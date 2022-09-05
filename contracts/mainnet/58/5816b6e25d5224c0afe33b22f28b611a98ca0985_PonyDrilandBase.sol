/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// File: build/solidity/base.sol


pragma solidity 0.8.16;

contract PonyDrilandBase {

    // Data
    address payable public owner;

    mapping (address => uint256) public interactions;

    mapping (address => mapping (uint256 => uint256)) public bookmark;
    mapping (address => mapping (string => uint256)) public nsfw_filter;
    mapping (address => uint256) public volume;
    mapping (address => uint256) public enabled;

    string public name;
    uint256 public wallets;
    uint256 public totalInteractions;

    // Event
    event Interaction(address indexed from, string value);
    event Enable(address indexed value);
    
    event Volume(address indexed from, string value);
    event NsfwFilter(address indexed from, string filter, uint256 value);
    event Bookmark(address indexed from, uint256 chapter, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Constructor
    constructor() {

        owner = payable(msg.sender);        
        name = "Pony Driland";

        wallets = 0;
        totalInteractions = 0;

    }

    // Transfer Owership
    function transferOwnership(address newOwner) public {
        require(address(msg.sender) == address(owner), "You are not allowed to do this.");
        emit OwnershipTransferred(owner, newOwner);
        owner = payable(newOwner);
    }

    // Owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // Enable Panel
    function enable() public returns (bool success) {

        // Update Wallet
        require(enabled[address(msg.sender)] <= 0, "This account is already activated.");
        enabled[address(msg.sender)] = 1;
        totalInteractions = totalInteractions + 1;
        wallets = wallets + 1;

        // Complete
        emit Enable(msg.sender);
        emit Interaction(msg.sender, "enable");
        return true;

    }

    function getWallets() external view returns (uint256) {
        return wallets;
    }

    function getInteractions() external view returns (uint256) {
        return totalInteractions;
    }

    // Bookemark
    function getBookmark(address _account, uint256 _chapter) external view returns (uint256) {
        return bookmark[_account][_chapter];
    }

    function insertBookmark(uint256 _chapter, uint256 amount) public returns (bool success) {
        
        // Complete
        require(enabled[address(msg.sender)] == 1, "You need to activate your account.");
        require(_chapter >= 1, "Invalid Chapter.");
        require(amount >= 0, "Invalid Value.");
        
        bookmark[address(msg.sender)][_chapter] = amount;
        interactions[address(msg.sender)] = interactions[address(msg.sender)] + 1;
        totalInteractions = totalInteractions + 1;

        emit Interaction(msg.sender, "insert_bookmark");
        return true;

    }

    // NSFW Filter
    function getNsfwFilter(address _account, string memory _name) external view returns (uint256) {
        return nsfw_filter[_account][_name];
    }

    function changeNsfwFilter(string memory _name, uint256 amount) public returns (bool success) {
        
        // Complete
        require(enabled[address(msg.sender)] == 1, "You need to activate your account.");
        require(amount >= 0, "Invalid Value. This is 1 or 0");
        require(amount <= 1, "Invalid Value. This is 1 or 0");

        nsfw_filter[address(msg.sender)][_name] = amount;
        interactions[address(msg.sender)] = interactions[address(msg.sender)] + 1;
        totalInteractions = totalInteractions + 1;

        emit Interaction(msg.sender, "change_nsfw_filter");
        return true;

    }

    // Volume
    function getVolume(address _account) external view returns (uint256) {
        return volume[_account];
    }

    function setVolume(uint256 amount) public returns (bool success) {
        
        // Complete
        require(enabled[address(msg.sender)] == 1, "You need to activate your account.");
        require(amount >= 0, "Invalid Volume. 0 - 100");
        require(amount <= 100, "Invalid Volume. 0 - 100");

        volume[address(msg.sender)] = amount;
        interactions[address(msg.sender)] = interactions[address(msg.sender)] + 1;
        totalInteractions = totalInteractions + 1;

        emit Interaction(msg.sender, "set_volume");
        return true;

    }
    
}