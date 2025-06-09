// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

/**
 * @title GaslessApproverOpenGSN
 * @dev Contract that allows users to approve token spending without paying gas
 * through meta-transactions using OpenGSN protocol
 */
contract GaslessApproverOpenGSN is EIP712, BaseRelayRecipient {
    using ECDSA for bytes32;

    // The address of the token spender contract
    address public tokenSpender;

    // Mapping to track nonces for each user to prevent replay attacks
    mapping(address => uint256) private _nonces;

    // EIP712 domain separator and type hash
    bytes32 private constant _APPROVAL_TYPEHASH = keccak256(
        "Approval(address owner,address token,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    event ApprovalSubmitted(address indexed owner, address indexed token, uint256 amount);

    constructor(address _tokenSpender, address _forwarder) EIP712("GaslessApproverOpenGSN", "1.0.0") {
        tokenSpender = _tokenSpender;
        _setTrustedForwarder(_forwarder);
    }

    /**
     * @dev Returns the name of this contract for OpenGSN compatibility
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
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
        // Ensure the real sender (not the forwarder) is the owner
        require(_msgSender() == owner, "GaslessApproverOpenGSN: sender is not the owner");
        
        // Ensure the deadline hasn't passed
        require(block.timestamp <= deadline, "GaslessApproverOpenGSN: approval expired");

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
        require(signer == owner, "GaslessApproverOpenGSN: invalid signature");

        // Execute the approval
        IERC20(token).approve(tokenSpender, amount);

        emit ApprovalSubmitted(owner, token, amount);
    }
} 