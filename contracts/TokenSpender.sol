// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenSpender
 * @dev Contract that can spend pre-approved tokens on behalf of users
 * This is a simplified version - you would typically add more business logic
 * for your specific use case
 */
contract TokenSpender is Ownable {
    // Mapping to keep track of approved operators who can trigger spends
    mapping(address => bool) public operators;
    
    // Event emitted when tokens are spent
    event TokensSpent(address indexed user, address indexed token, uint256 amount, address recipient);
    
    // Event emitted when operator status changes
    event OperatorStatusChanged(address indexed operator, bool status);

    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Sets the operator status for an address
     * @param operator The address to modify
     * @param status New operator status
     */
    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorStatusChanged(operator, status);
    }
    
    /**
     * @dev Spends tokens on behalf of a user
     * @param user The user whose tokens will be spent
     * @param token The token to spend
     * @param amount The amount to spend
     * @param recipient The recipient of the tokens
     */
    function spendTokens(
        address user,
        address token,
        uint256 amount,
        address recipient
    ) external {
        // Either owner or approved operator can spend tokens
        require(msg.sender == owner() || operators[msg.sender], "TokenSpender: caller is not authorized");
        
        // Transfer tokens from user to recipient
        // Note: This requires that the user has already approved this contract to spend their tokens
        bool success = IERC20(token).transferFrom(user, recipient, amount);
        require(success, "TokenSpender: token transfer failed");
        
        emit TokensSpent(user, token, amount, recipient);
    }
    
    /**
     * @dev Checks if a user has given sufficient allowance to this contract
     * @param user The user to check
     * @param token The token to check
     * @param amount The amount to check against
     * @return true if the allowance is sufficient, false otherwise
     */
    function checkAllowance(address user, address token, uint256 amount) external view returns (bool) {
        return IERC20(token).allowance(user, address(this)) >= amount;
    }
    
    /**
     * @dev Batch spend function to save gas when spending multiple tokens
     * @param users Array of users whose tokens will be spent
     * @param tokens Array of tokens to spend
     * @param amounts Array of amounts to spend
     * @param recipients Array of recipients for the tokens
     */
    function batchSpendTokens(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        address[] calldata recipients
    ) external {
        // Either owner or approved operator can spend tokens
        require(msg.sender == owner() || operators[msg.sender], "TokenSpender: caller is not authorized");
        
        // All arrays must have the same length
        require(
            users.length == tokens.length && 
            tokens.length == amounts.length && 
            amounts.length == recipients.length,
            "TokenSpender: array length mismatch"
        );
        
        for (uint256 i = 0; i < users.length; i++) {
            bool success = IERC20(tokens[i]).transferFrom(users[i], recipients[i], amounts[i]);
            require(success, "TokenSpender: token transfer failed");
            
            emit TokensSpent(users[i], tokens[i], amounts[i], recipients[i]);
        }
    }
} 