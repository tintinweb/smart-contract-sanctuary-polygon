/**
 *Submitted for verification at polygonscan.com on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DiscordLink is Ownable {
    uint256 public cost = 1.7 ether;
    uint256 public totalLinked;
    address public withdrawAddress = 0xE024bb3E3bD1B68C101f604f742CeA66ecC4A2d2;
    mapping(address => string[]) public walletInfo;
    mapping(string => address) public walletFromDiscord;
    mapping(string => string[]) public guildInfo;
    mapping(string => string) public guildFromAddress;
    mapping(string => bool) public whiteList;
    event discordLink(address msgSender, string _discordID, string _guildID);
    event projectInit(string _mintAddress, string _guildID, string _chain);

    function linkDiscord(string calldata _discordID, string calldata _guildID)
        public
        payable
    {
        require(utfStringLength(_discordID) >= 18, "Must Input a Discord ID");
        require(testStr(_discordID) == true, "Must Input a Valid Discord ID");
        require(utfStringLength(_guildID) >= 18, "Must Input a Guild ID");
        require(testStr(_guildID) == true, "Must Input a Valid Guild ID");
        require(!listChecker(_guildID), "Guild Already Linked");
        require(
            walletFromDiscord[_discordID] == address(0) ||
                walletFromDiscord[_discordID] == msg.sender,
            "Wallet Already Linked"
        );
        if (!whiteList[_guildID]) {
            require(msg.value >= cost, "Insufficient Funds");
        }
        if (walletInfo[msg.sender].length >= 2) {
            walletInfo[msg.sender].push(_guildID);
        } else {
            walletInfo[msg.sender] = [_discordID, _guildID];
            walletFromDiscord[_discordID] = msg.sender;
        }
        emit discordLink(msg.sender, _discordID, _guildID);
    }

    function adminDiscordLink(
        string calldata _discordID,
        address _address,
        string calldata _guildID
    ) public onlyOwner {
        require(utfStringLength(_discordID) >= 18, "Must Input a Discord ID");
        require(testStr(_discordID) == true, "Must Input a Valid Discord ID");
        require(utfStringLength(_guildID) >= 18, "Must Input a Guild ID");
        require(testStr(_guildID) == true, "Must Input a Valid Guild ID");
        walletInfo[_address] = [_discordID, _guildID];
        walletFromDiscord[_discordID] = _address;
        emit discordLink(_address, _discordID, _guildID);
    }

    function adminLinkProject(
        string calldata _mintAddress,
        string calldata _guildID,
        string calldata _roleID,
        string calldata _tokens,
        string calldata _chain
    ) public onlyOwner {
        require(utfStringLength(_guildID) >= 18, "Must Input a Guild ID");
        require(testStr(_guildID) == true, "Must Input a Valid Guild ID");
        guildInfo[_guildID] = [_mintAddress, _roleID, _tokens, _chain];
        guildFromAddress[_mintAddress] = _guildID;
        totalLinked++;
        emit projectInit(_mintAddress, _guildID, _chain);
    }

    function guildInfoChecker(string calldata _guildID)
        internal
        view
        returns (bool)
    {
        if (guildInfo[_guildID].length > 0) {
            return true;
        }
        return false;
    }

    function listChecker(string calldata _guildID)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < walletInfo[msg.sender].length; i++) {
            if (stringsEquals(_guildID, walletInfo[msg.sender][i])) {
                return true;
            }
        }
        return false;
    }

    function setWhitelist(string[] calldata _guilds, bool _value)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _guilds.length; i++) {
            whiteList[_guilds[i]] = _value;
        }
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function stringsEquals(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i = 0; i < l1; i++) {
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }

    function testStr(string calldata str) internal pure returns (bool) {
        bytes memory b = bytes(str);

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) //9-0
            ) return false;
        }

        return true;
    }

    function utfStringLength(string memory str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    function setAddress(address _address) public onlyOwner {
        withdrawAddress = _address;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }
}