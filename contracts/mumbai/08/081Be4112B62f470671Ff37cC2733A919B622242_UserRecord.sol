/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title UserRecord
 * @author ZentrixLab
 */
contract UserRecord {
    
    // owner of the smart contract
    address private _owner;

    // all addresses
    address[] public allAddresses;

    // data stored on chain for each address
    struct Data {
        bytes32 hash;
        bool allowed;
        uint256 time;
    }

    // mapping address to data struct
    mapping(address => Data) public record;

    struct ModelData {
        address[] addresses;
        uint256 time;
    }

    mapping(bytes32 => ModelData) public models;

    bytes32[] public allModelsHashes;

    /**
     * @dev struct that represents input data
     * @param addr address of the wallet
     * @param hash bytes32 hash made of set of images in database
     */
    struct InputData {
        address addr;
        bytes32 hash;
    }

    // format for returning address with timestamp
    struct AddressWithTime {
        address addr;
        uint256 time;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Function used to change owner of the contract
     */
    function changeOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Adds new users to record and updates allowedAddresses array, can be called only by owner
     * @param newUsers array of InputData structs that contains user address string and status boolean
     * @notice newUsers should be passed as [["addressString", true/false, "image hash"], ["addressString", true/false, "image hash"]] from TypeScript
     */
    function addUsers(InputData[] calldata newUsers) external onlyOwner {
        for (uint256 i = 0; i < newUsers.length; ++i) {
            _addUser(newUsers[i]);
        }
        // _updateAllowed();
    }

    function revokeAccess() external {
        require(record[msg.sender].hash != 0, "Address not on the blockchain");
        _revokeAccess(msg.sender);
        // _updateAllowed();
    }

    /**
     * @dev Returns an array of all allowed addresses
     */
    function fetchAllowed() external view returns (address[] memory) {
        address[] memory allowed = new address[](allAddresses.length);
        uint256 index = 0;
        for (uint256 i = 0; i < allAddresses.length; ++i) {
            if (record[allAddresses[i]].allowed) {
                allowed[index] = allAddresses[i];
                index++;
            }
        }
        return allowed;
    }

    /**
     * @dev Returns an array of all addresses that are not allowed with timestamps when they have been revoked
     */
    function fetchRevoked() external view returns (AddressWithTime[] memory) {
        AddressWithTime[] memory notAllowed = new AddressWithTime[](allAddresses.length);
        uint256 index = 0;
        for (uint256 i = 0; i < allAddresses.length; ++i) {
            if (record[allAddresses[i]].allowed) {
                notAllowed[index] = AddressWithTime(allAddresses[i], record[allAddresses[i]].time);
                index++;
            }
        }
        return notAllowed;
    }

    /**
     * @dev Function that transfer ERC20 tokens from contract owner to everyone that contributed with a valid pictures for model
     * @param validAddresses array of address strings of all users that have valid pictures
     * @param token address string of ERC20 token on Polygon chain that should be send to valid addresses
     * @param amount uint256 number of tokens to transfer to each account (will be multiplied by 1e18)
     * @notice contract owner must have balance of token greater then number of addresses in validAddresses array
     */
    function transferTokens(address[] memory validAddresses, IERC20 token, uint256 amount) external onlyOwner {
        _transferTokens(validAddresses, token, amount);
    }

    /**
     * @dev Creates new model
     */
    function createModel(bytes32 modelHash, address[] memory addresses) external onlyOwner {
        allModelsHashes.push(modelHash);
        for (uint256 i = 0; i < addresses.length; ++i) {
            models[modelHash].addresses.push(addresses[i]);
        }
        models[modelHash].time = block.timestamp;
    }

    /**
     * @dev Function that returns all data stored in model(addresses and timestamp)
     */
    function fetchModel(bytes32 modelHash) external view onlyOwner returns(ModelData memory) {
        return models[modelHash];
    }

    /**
     * @dev Function that check if value of allowed is true for all addresses in input array
     * @return array of addresses that are not allowed
     */
    function checkAllowance(address[] calldata addresses) external view onlyOwner returns(address[] memory) {
        address[] memory notAllowed = new address[](addresses.length);
        uint256 index = 0;
        for (uint256 i = 0; i < addresses.length; ++i) {
            if (!record[addresses[i]].allowed) {
                notAllowed[index] = addresses[i];
                index++;
            }
        }
        return notAllowed;
    }

    // ### Internal functions ###
    /**
     * @dev Adds new user to record
     */
    function  _addUser(InputData calldata user) internal {
        // if address already has been used, then skip it
        // require(record[user.addr].hash == 0, "Already used address");        
        if (record[user.addr].hash == 0) {
            // when new user is added default value for allowed is true
            record[user.addr] = Data(user.hash, true, block.timestamp);
            allAddresses.push(user.addr);
        }
    }

    /**
     * @dev Revokes access permission for address
     */
    function _revokeAccess(address addr) internal {
        record[addr].allowed = false;
        record[addr].time = block.timestamp;
    }

    /**
     * @dev Transfer ERC20 tokens from owners address to smart contract and from smart contract to all addresses that have valid images on blockchain
     */
    function _transferTokens(address[] memory validAddresses, IERC20 token, uint256 amount) internal {
        require(token.balanceOf(msg.sender) >= validAddresses.length * 1 ether, "Not enough coins");
	    require(token.allowance(msg.sender, address(this)) >= validAddresses.length, "Not enough allowance");
        for (uint256 i = 0; i < validAddresses.length; i++) {
            bool sent = token.transferFrom(msg.sender, validAddresses[i], amount * 1 ether);
            require(sent, "Transfer from contract to addresses failed");
        }
    }
}


/**
 * @dev Interface for ERC20 token (pasted from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol")
 */

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}