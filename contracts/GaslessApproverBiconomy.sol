// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title GaslessApprover
 * @dev Contract that allows users to approve token spending without paying gas
 * through meta-transactions following EIP-2771
 */
contract GaslessApproverBiconomy is EIP712 {
    using ECDSA for bytes32;

    // The address of the token spender contract
    address public tokenSpender;

    // The address of the trusted forwarder (Biconomy's forwarder)
    address public trustedForwarder;

    // Mapping to track nonces for each user to prevent replay attacks
    mapping(address => uint256) private _nonces;

    // EIP712 domain separator and type hash
    bytes32 private constant _APPROVAL_TYPEHASH = keccak256(
        "Approval(address owner,address token,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    event ApprovalSubmitted(address indexed owner, address indexed token, uint256 amount);

    constructor(address _tokenSpender, address _trustedForwarder) EIP712("GaslessApprover", "1.0.0") {
        tokenSpender = _tokenSpender;
        trustedForwarder = _trustedForwarder;
    }

    /**
     * @dev Returns the current nonce for an address
     */
    function getNonce(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev Verifies the signature and executes the token approval
     * @param owner The address of the token owner
     * @param token The address of the token to approve
     * @param amount The amount to approve
     * @param deadline The deadline after which the signature is no longer valid
     * @param signature The signature produced by the owner
     */
    function approveWithSignature(
        address owner,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external {
        // Ensure the transaction is sent through the trusted forwarder
        require(_msgSender() == trustedForwarder, "GaslessApprover: caller is not the trusted forwarder");
        
        // Ensure the deadline hasn't passed
        require(block.timestamp <= deadline, "GaslessApprover: approval expired");

        // Verify signature
        bytes32 structHash = keccak256(
            abi.encode(
                _APPROVAL_TYPEHASH,
                owner,
                token,
                amount,
                _nonces[owner]++,
                deadline
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == owner, "GaslessApprover: invalid signature");

        // Execute the approval
        IERC20(token).approve(tokenSpender, amount);

        emit ApprovalSubmitted(owner, token, amount);
    }

    /**
     * @dev Returns the address of the sender, accounting for meta-transactions
     */
    function _msgSender() internal view returns (address) {
        if (msg.sender == trustedForwarder) {
            // Extract the sender address from the last 20 bytes of msg.data
            // This is specific to Biconomy's implementation of the trusted forwarder
            bytes memory data = msg.data;
            assembly {
                // Load the sender address from calldata at position (len(msg.data) - 20)
                let sender := calldataload(sub(calldatasize(), 20))
                // Mask to the last 20 bytes (address size)
                sender := and(sender, 0xffffffffffffffffffffffffffffffffffffffff)
                mstore(add(data, 36), sender)
            }
            return address(uint160(uint256(bytes32(data))));
        }
        return msg.sender;
    }

    /**
     * @dev Function to check if a relayer is trusted
     */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == trustedForwarder;
    }
} 