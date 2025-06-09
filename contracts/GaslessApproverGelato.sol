// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGelatoRelay {
    function sponsoredCall(
        address target,
        bytes calldata data,
        address sponsor,
        address feeToken,
        uint256 fee
    ) external;
}

/**
 * @title GaslessApproverGelato
 * @dev Contract that allows users to approve token spending without paying gas
 * through meta-transactions using Gelato Relay
 */
contract GaslessApproverGelato is EIP712, Ownable {
    using ECDSA for bytes32;

    // The address of the token spender contract
    address public tokenSpender;
    
    // The address of Gelato Relay contract
    address public gelatoRelay;
    
    // The address that will sponsor the transactions
    address public sponsor;

    // Mapping to track nonces for each user to prevent replay attacks
    mapping(address => uint256) private _nonces;

    // EIP712 domain separator and type hash
    bytes32 private constant _APPROVAL_TYPEHASH = keccak256(
        "Approval(address owner,address token,uint256 amount,uint256 nonce,uint256 deadline)"
    );

    event ApprovalSubmitted(address indexed owner, address indexed token, uint256 amount);
    event SponsorUpdated(address indexed oldSponsor, address indexed newSponsor);
    event GelatoRelayUpdated(address indexed oldRelay, address indexed newRelay);

    constructor(
        address _tokenSpender, 
        address _gelatoRelay, 
        address _sponsor
    ) EIP712("GaslessApproverGelato", "1.0.0") Ownable(msg.sender) {
        tokenSpender = _tokenSpender;
        gelatoRelay = _gelatoRelay;
        sponsor = _sponsor;
    }

    /**
     * @dev Returns the current nonce for an address
     */
    function getNonce(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev Update the sponsor address
     * @param _sponsor The new sponsor address
     */
    function setSponsor(address _sponsor) external onlyOwner {
        address oldSponsor = sponsor;
        sponsor = _sponsor;
        emit SponsorUpdated(oldSponsor, _sponsor);
    }

    /**
     * @dev Update the Gelato Relay address
     * @param _gelatoRelay The new Gelato Relay address
     */
    function setGelatoRelay(address _gelatoRelay) external onlyOwner {
        address oldRelay = gelatoRelay;
        gelatoRelay = _gelatoRelay;
        emit GelatoRelayUpdated(oldRelay, _gelatoRelay);
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
        // Ensure the deadline hasn't passed
        require(block.timestamp <= deadline, "GaslessApproverGelato: approval expired");

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
        require(signer == owner, "GaslessApproverGelato: invalid signature");

        // Execute the approval
        IERC20(token).approve(tokenSpender, amount);

        emit ApprovalSubmitted(owner, token, amount);
    }

    /**
     * @dev Provides the data needed to execute an approval via Gelato Relay
     * @param owner The address of the token owner
     * @param token The address of the token to approve
     * @param amount The amount to approve
     * @param deadline The deadline after which the signature is no longer valid
     * @param signature The signature produced by the owner
     * @return The function call data for Gelato Relay
     */
    function getApprovalCalldata(
        address owner,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) external pure returns (bytes memory) {
        return abi.encodeWithSelector(
            this.approveWithSignature.selector,
            owner,
            token,
            amount,
            deadline,
            signature
        );
    }

    /**
     * @dev Relays an approval transaction through Gelato
     * @param owner The address of the token owner
     * @param token The address of the token to approve
     * @param amount The amount to approve
     * @param deadline The deadline after which the signature is no longer valid
     * @param signature The signature produced by the owner
     * @param feeToken The token used to pay Gelato fees (address(0) for native token)
     * @param fee The fee amount to pay Gelato
     */
    function relayApproval(
        address owner,
        address token,
        uint256 amount,
        uint256 deadline,
        bytes memory signature,
        address feeToken,
        uint256 fee
    ) external {
        bytes memory data = abi.encodeWithSelector(
            this.approveWithSignature.selector,
            owner,
            token,
            amount,
            deadline,
            signature
        );
        
        IGelatoRelay(gelatoRelay).sponsoredCall(
            address(this),
            data,
            sponsor,
            feeToken,
            fee
        );
    }
} 