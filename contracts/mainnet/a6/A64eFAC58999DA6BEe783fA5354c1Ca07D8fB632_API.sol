/**
 *Submitted for verification at polygonscan.com on 2022-04-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract API {
    address public protocol;
    address public owner;

    mapping(address => string) public staticData;
    mapping(address => uint256) public tokenAssetId;
    Token[] public assets;
    mapping(uint256 => Token) public assetById;

    struct Token {
        string ipfsHash;
        address[] contractAddresses;
        uint256 id;
        address[] totalSupply;
        address[] excludedFromCirculation;
        uint256 lastUpdate;
        uint256 utilityScore;
        uint256 socialScore;
        uint256 trustScore;
        uint256 marketScore;
    }

    event NewListing(address indexed token, string ipfsHash);

    event NewAssetListing(Token token);

    constructor(address _protocol, address _owner) {
        protocol = _protocol;
        owner = _owner;
    }

    function getAllAssets() external view returns (Token[] memory) {
        return assets;
    }

    function addStaticData(
        address token,
        string memory ipfsHash,
        uint256 assetId
    ) external {
        require(
            protocol == msg.sender || owner == msg.sender,
            "Only the DAO or the Protocol can add data."
        );
        staticData[token] = ipfsHash;
        tokenAssetId[token] = assetId;
        emit NewListing(token, ipfsHash);
    }

    function addAssetData(Token memory token) external {
        require(
            protocol == msg.sender || owner == msg.sender,
            "Only the DAO or the Protocol can add data."
        );
        assets.push(token);
        assetById[token.id] = token;

        for (uint256 i = 0; i < token.contractAddresses.length; i++) {
            staticData[token.contractAddresses[i]] = token.ipfsHash;
        }

        emit NewAssetListing(token);
    }

    function removeStaticData(address token) external {
        require(owner == msg.sender);
        delete staticData[token];
    }

    function setProtocolAddress(address _protocol) external {
        require(
            owner == msg.sender,
            "Only the DAO can modify the Protocol address."
        );
        protocol = _protocol;
    }
}