// SPDX-License-Identifier: CC0

pragma solidity ^0.8.8; // 0.8.8 removes the requirement to add "override" to functions implementing an interface

import "IERC4974.sol";

/// @title Example SocialToken System
contract SocialToken is IERC4974 {

    address operator;
    address constant ZERO_ADDRESS = address(0); 
    uint256 totalTokens;
    mapping(address => uint256) public wallet_balance;

    constructor(uint256 _initialSupply) {
        operator = msg.sender;
        totalTokens = _initialSupply;
   }

    function setOperator(address _operator) external {
        ///  @dev EIP-4974 designates that the function: 
        ///  MUST throw unless `msg.sender` is `operator`.
        require(operator == msg.sender, "Only the current Operator can call setOperator.");
        
        ///  @dev MUST throw if `operator` address is either already current `operator`
        ///  or is the zero address.
        require(_operator != operator, "Address is already the current operator.");
        require(_operator != ZERO_ADDRESS, "Operator cannot be the zero address.");

        operator = _operator;

        emit Appointment(operator);
    }

    function getOperator() view external returns(address) {
        return operator;
    }

    // This function is only transferring from the contract despite the addition of the _to param
    // What needs to change to ensure user-to-user transfers can occur? 
    function transfer(address _to, uint256 _amount) external {
        /// @notice Transfer EXP from one address to a participating address.
        /// @param _to Address to which EXP tokens at `from` address will transfer.
        /// @param _amount Total EXP tokens to reallocate.
        /// @dev MUST throw unless `msg.sender` is `operator`.
        require(msg.sender == operator, "Only the operator can transfer tokens.");

        ///  SHOULD throw if `amount` is zero.
        require(_amount > 0, "Must transfer a non-zero amount.");

        ///  MUST throw if `to` and `from` are the same address.
        //require(_from != _to, "Cannot transfer to self.");

        // Check that tokens being transferred from _from are not greater than the number of tokens present in the address
        //require(wallet_balance[_from] > _amount, "Transfering address has less tokens than what transaction is attempting to transfer.");

        ///  MAY allow minting from zero address, burning to the zero address, 
        ///  transferring between accounts, and transferring between contracts.
        wallet_balance[_to] += _amount;
        // The offending line is below - we're only changing the value of totalTokens in the contract, not changing the value of tokens in _from 
        totalTokens -= _amount;

        ///  MUST emit a Transfer event with each successful call.
        emit Transfer(_to, _amount);
    }

    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return wallet_balance[_wallet];
    }

    function burn(address _from, uint256 _amount) external {
        /// @notice Burn EXP.
        /// @param _from Address from which to burn EXP tokens.
        /// @param _amount Total EXP tokens to burn.
        /// @dev MUST throw unless `msg.sender` is `operator`.
        require(msg.sender == operator, "Only the operator can burn tokens.");

        ///  SHOULD throw if `amount` is zero.
        require(_amount > 0, "Must burn a non-zero amount.");

        /// Check that tokens being transferred from _from are not greater than the number of tokens present in the address
        require(wallet_balance[_from] >= _amount, "Targeted address has less tokens than what transaction is attempting to burn.");

        /// Burn tokens 
        wallet_balance[_from] -= _amount;

        ///  MUST emit a Transfer event with each successful call.
        emit Burn(_from, _amount);
    }
}

// SPDX-License-Identifier: CC0

pragma solidity ^0.8.8;

/// @title ERC-4974 Experience (EXP) Token Standard
/// @dev See https://eips.ethereum.org/EIPS/EIP-4974
///  Note: the ERC-165 identifier for this interface is 0x696e7752.
///  Must initialize contracts with an `operator` address that is not `address(0)`.
///  Must initialize contracts assigning participation as `true` for both `operator` and `address(0)`.
interface IERC4974 /* is ERC165 */ {

    /// @dev Emits when operator changes.
    ///  MUST emit when `operator` changes by any mechanism.
    ///  MUST ONLY emit by `setOperator`.
    event Appointment(address indexed _operator);

    /// @dev Emits when operator transfers EXP. 
    ///  MUST emit when EXP is transferred by any mechanism.
    ///  MUST ONLY emit by `transfer`.
    event Transfer(address indexed _to, uint256 _amount);

    /// @dev Emits when operator burns EXP. 
    ///  MUST emit when EXP is burned by any mechanism.
    ///  MUST ONLY emit by `burn`.
    event Burn(address indexed _from, uint256 _amount);

    /// @notice Appoint operator authority.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw if `operator` address is either already current `operator`
    ///  or is the zero address.
    ///  MUST emit an `Appointment` event.
    /// @param _operator New operator of the smart contract.
    function setOperator(address _operator) external;

    /// @notice Transfer EXP from one address to a participating address.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw unless `to` address is participating.
    ///  MUST throw if `to` and `from` are the same address.
    ///  MUST emit a Transfer event with each successful call.
    ///  SHOULD throw if `amount` is zero.
    ///  MAY allow minting from zero address, burning to the zero address, 
    ///  transferring between accounts, and transferring between contracts.
    ///  MAY limit interaction with non-participating `from` addresses.
    /// @param _to Address to which EXP tokens at `from` address will transfer.
    /// @param _amount Total EXP tokens to reallocate.
    function transfer(address _to, uint256 _amount) external;

    /// @notice Burn EXP from one address.
    /// @dev MUST throw unless `msg.sender` is `operator`.
    ///  MUST throw unless `to` address is participating.
    ///  MUST throw if `to` and `from` are the same address.
    ///  MUST emit a Transfer event with each successful call.
    ///  SHOULD throw if `amount` is zero.
    ///  MAY allow minting from zero address, burning to the zero address, 
    ///  transferring between accounts, and transferring between contracts.
    ///  MAY limit interaction with non-participating `from` addresses.
    /// @param _from Address from which to transfer EXP tokens.
    /// @param _amount Total EXP tokens to reallocate.
    function burn(address _from, uint256 _amount) external;

    /// @notice Return total EXP managed by this contract.
    /// @dev MUST sum EXP tokens of all `participant` addresses, 
    ///  regardless of participation status, excluding only the zero address.
    function totalSupply() external view returns (uint256);

    /// @notice Return total EXP allocated to a participant.
    /// @dev MUST register each time `Transfer` emits.
    ///  SHOULD throw for queries about the zero address.
    /// @param _participant An address for whom to query EXP total.
    /// @return uint256 The number of EXP allocated to `participant`, possibly zero.
    function balanceOf(address _participant) external view returns (uint256);
}

interface IERC165 {
    /// @notice Query if a contract implements an interface.
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @param interfaceID The interface identifier, as specified in ERC-165.
    /// @return bool `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise.
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}