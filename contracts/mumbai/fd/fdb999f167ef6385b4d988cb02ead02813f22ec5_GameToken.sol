// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Context.sol";
import "../Ownable.sol";
import "../ERC20.sol";
import "../Pausable.sol";

/**
 * @title GameToken
 */
contract GameToken is Context, Ownable, ERC20, Pausable {
    uint256 private constant MAX_SUPPLY = 20000000 * 10 ** 18;
    uint8 private constant DECIMALS = 18;
    uint256 private constant UNIT = 10 ** uint256(DECIMALS);
    uint256 private constant MAX_TX_AMOUNT = 20000 * UNIT;
    uint256 private constant MAX_TX_INTERVAL = 2 minutes;
    //address private armoryNftContract;

    address private _admin;
    mapping(address => uint256) private _lastTxTimestamp;

    //WhiteList 
    address[] public allowedAddresses;
    mapping(address => bool) public isAllowed;


    // only admin account can unlock escrow
    modifier onlyAdmin() {
        require(_msgSender() == _admin, "GameToken: only admin can call this function");
        _;
    }

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _admin = _msgSender();
        _mint(_admin, MAX_SUPPLY);
    }

    /**
    * @dev Returns max supply of the token (20 million tokens).
    */
    function maxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev Returns single unit of account.
     */
    function unit() public pure returns (uint256) {
        return UNIT;
    }

    //Add Whitelist
    function addFromWhitelist(address _address) public onlyOwner {
        require(!isAllowed[_address], "Address is already allowed.");
        allowedAddresses.push(_address);
        isAllowed[_address] = true;
    }
    //Remove Whitelist
    function removeFromWhitelist(address _address) public onlyOwner {
        require(isAllowed[_address], "Address is not allowed.");
        isAllowed[_address] = false;
        for (uint256 i = 0; i < allowedAddresses.length; i++) {
            if (allowedAddresses[i] == _address) {
                allowedAddresses[i] = allowedAddresses[allowedAddresses.length - 1];
                allowedAddresses.pop();
                break;
            }
        }
    }

    /**
     * @dev Mint tokens.
     */
    function mint() public onlyAdmin {
        uint256 currentSupply = totalSupply();
        uint256 newSupply = currentSupply + MAX_SUPPLY;

        require(newSupply <= 2 * MAX_SUPPLY, "GameToken: total supply exceeds max supply");
        _mint(_admin, MAX_SUPPLY);
    }


    /**
     * @dev Allows the current admin to transfer control of the contract to a newAdmin.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "GameToken: new admin is the zero address");
        _admin = newAdmin;
    }

    /**
     * @dev Approve allowance for escrow/P2EGame contract to use (spender).
     */
    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        require(spender != address(0), "GameToken: approve to the zero address");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens.
     */
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        require(recipient != address(0), "GameToken: transfer to the zero address");
        require(amount > 0, "GameToken: transfer amount must be greater than zero");
        require(amount <= balanceOf(_msgSender()), "GameToken: insufficient balance");

        if (isAllowed[_msgSender()]) {
            // allow transfer to whitelisted addresses
            _lastTxTimestamp[recipient] = block.timestamp;
            _transfer(_msgSender(), recipient, amount);
            return true;
        } else {
            // regular transfer
            require(_lastTxTimestamp[recipient] + MAX_TX_INTERVAL < block.timestamp, "GameToken: Please Hold min 2 minutes Bot prevent");
            require(_lastTxTimestamp[_msgSender()] + MAX_TX_INTERVAL < block.timestamp, "GameToken: transfer not allowed yet respect the time 2 minutes! Bot prevent");
            _lastTxTimestamp[_msgSender()] = block.timestamp;
            _lastTxTimestamp[recipient] = block.timestamp;
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    }
}