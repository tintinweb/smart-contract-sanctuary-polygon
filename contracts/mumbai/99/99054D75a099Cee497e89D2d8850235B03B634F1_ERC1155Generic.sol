/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

// File: contracts\tokens\IERC1155.sol
// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.5; 

/// @title ERC-1155 Multi Token Standard
/// @dev ee https://eips.ethereum.org/EIPS/eip-1155
///  The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).        
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).      
        The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).                
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).        
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.        
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts\tokens\IERC1155TokenReceiver.sol


pragma solidity 0.8.5; 

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}

// File: contracts\tokens\IERC165.sol


pragma solidity 0.8.5; 

/// @title IERC165
/// @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts\tokens\ERC1155Generic.sol

// ┬⌐ Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 
/// @author Guillaume Gonnaud and Javier Fraile 2021
/// @title ERC1155 Generic placeholder smart contract for testing and ABI
contract ERC1155Generic is IERC1155, IERC165 {

    string public name; // Returns the name of the token - e.g. "Generic ERC1155".
    string public symbol; // Returns the symbol of the token. E.g. GEN1155.

    address public owner;

    mapping(address => mapping(uint256 => uint256)) internal balanceOfVar; // owner => id => balance
    mapping(address => mapping(address => bool)) internal isApprovedForAllVar; // owner => oprator => isapproved ?

    
    /// @notice Constructor
    /// @dev Please change the values in here if you want more specific values, or make the constructor takes arguments
    constructor()
    {
        owner = msg.sender;
        name = "Generic ERC1155";
        symbol = "GEN1155";
    }


    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// MUST revert on any other error.
    /// UST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).        
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _id      ID of the token type
    /// @param _value   Transfer amount
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override {
        require(msg.sender == _from || isApprovedForAllVar[_from][msg.sender], "safeTransferFrom: msg.sender is not allowed to manipulate _from tokens");
        require(_to != address(0x0), "safeTransferFrom: cannot transfer to 0x0");
        require(_value <= balanceOfVar[_from][_id], "safeTransferFrom: Balance of _from is too low to transfer _value tokens");

        //Adjusting the balances
        balanceOfVar[_from][_id] = balanceOfVar[_from][_id] - _value;
        balanceOfVar[_to][_id] = balanceOfVar[_to][_id] + _value;

        //Emitting the event
        emit TransferSingle(msg.sender, _from,  _to, _id, _value);

        if(isContract(_to)){
            //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) == 0xf23a6e61
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == bytes4(0xf23a6e61));
        }
    
    }


    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if length of `_ids` is not the same as length of `_values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// MUST revert on any other error.        
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _ids     IDs of each token type (order and length must match _values array)
    /// @param _values  Transfer amounts per token type (order and length must match _ids array)
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override {
        require(msg.sender == _from || isApprovedForAllVar[_from][msg.sender], "safeBatchTransferFrom: msg.sender is not allowed to manipulate _from tokens");
        require(_to != address(0x0), "safeBatchTransferFrom: cannot transfer to 0x0");
        require(_ids.length == _values.length, "safeBatchTransferFrom: _ids and _values lenght mismatch");

        uint256 tmp;
        while(tmp < _ids.length){ //using while for 0 case optimization
            require(_values[tmp] <= balanceOfVar[_from][_ids[tmp]], "safeBatchTransferFrom: Balance of _from is too low to transfer _values tokens");

            //Adjusting the balances
            balanceOfVar[_from][_ids[tmp]] = balanceOfVar[_from][_ids[tmp]] - _values[tmp];
            balanceOfVar[_to][_ids[tmp]] = balanceOfVar[_to][_ids[tmp]] + _values[tmp];
        }

        //Emitting the event
        emit TransferBatch(msg.sender, _from,  _to, _ids, _values);

        if(isContract(_to)){
            //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")) == 0xf23a6e61
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == bytes4(0xbc197c81));
        }
        
    }


    /// @notice Get the balance of an account's tokens.
    /// @param _owner  The address of the token holder
    /// @param _id     ID of the token
    /// @return        The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id) external override view returns (uint256){
        return balanceOfVar[_owner][_id];
    }


    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _ids    ID of the tokens
    /// @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external override view returns (uint256[] memory){

        //Making value readable from stack directly instead of having to read the stack as pointer to get length = less gas when looping
        uint256 ownerslength = _owners.length;
        uint256 idslength =  _ids.length;

        uint256[] memory retour = new uint256[](ownerslength * idslength); 
        
        uint256 i;
        uint256 j;

        //using while for 0 case optimization
        while(i < ownerslength){ //iterating owners
            while(j < idslength){ //iterating _ids
                retour[i*idslength + j] = balanceOfVar[_owners[i]][_ids[j]];
                j++;
            }
            delete j; //Depending of EVM/compiler could refund some gas instead of = 0;
            i++;
        }
        return retour;
    }


    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator  Address to add to the set of authorized operators
    /// @param _approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external override{
   //mapping(address => mapping(address => bool)) internal isApprovedForAllVar; // owner => oprator => isapproved ?
        isApprovedForAllVar[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }


    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner     The owner of the tokens
    /// @param _operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address _owner, address _operator) external override view returns (bool){
        return  isApprovedForAllVar[_owner][_operator];
    }


    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external override pure returns (bool){
        return (interfaceID == 0xd9b67a26);
    }


    /// @notice Mint tokens for message.sender
    /// @param _id      The tokens ID
    /// @param _value   Minted amount
    function mint(uint256 _id, uint256 _value) external{

        //Adjusting the balance
        balanceOfVar[msg.sender][_id] = balanceOfVar[msg.sender][_id] + _value;

        //Emitting the event
        emit TransferSingle(msg.sender, address(0x0),  msg.sender, _id, _value);

        if(isContract(msg.sender)){
            //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) == 0xf23a6e61
            require(IERC1155TokenReceiver(msg.sender).onERC1155Received(msg.sender, msg.sender, _id, _value, "") == bytes4(0xf23a6e61));
        }
    
    }

    
    /// @notice Mint tokens for message.sender
    /// @param _ids      The tokens IDs
    /// @param _values   Minted amounts. length must match _ids
    function mint(uint256[] calldata _ids, uint256[] calldata _values) external{

        require(_ids.length == _values.length, "mint: _ids and _values lenght mismatch");

        uint256 tmp;
        while(tmp < _ids.length){ //using while for 0 case optimization
            balanceOfVar[msg.sender][_ids[tmp]] = balanceOfVar[msg.sender][_ids[tmp]] + _values[tmp];
        }

        //Emitting the event
        emit TransferBatch(msg.sender, address(0x0),  msg.sender, _ids, _values);

        if(isContract(msg.sender)){
            //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")) == 0xf23a6e61
            require(IERC1155TokenReceiver(msg.sender).onERC1155BatchReceived(msg.sender, address(0x0), _ids, _values, "") == bytes4(0xbc197c81));
        }
    
    }


    /// @notice Check if an address is a contract
    /// @param _address The adress you want to test
    /// @return true if the address has bytecode, false if not
    function isContract(address _address) internal view returns(bool){
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_address) }
        return (codehash != accountHash && codehash != 0x0);
    }

}