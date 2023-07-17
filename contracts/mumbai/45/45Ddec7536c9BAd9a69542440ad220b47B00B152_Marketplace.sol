/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/IERC20.sol

pragma solidity >=0.8.2 <0.9.0;

interface Token {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

}

// File: contracts/TransferHelper.sol

pragma solidity >=0.8.4;

// helper methods for intrcting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeApprove: approve failed");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeTransfer: transfer failed");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address, address, uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data,(bool))),"TransferHelper: safeTransferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: safeTransferETH: ETH transfer failed");
    }
}

// File: contracts/Ownable.sol

pragma solidity >=0.8.4;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /** 
    * @dev The Ownable constructor sets the orignal 'owner' of the contract to the sender *account
    */
    constructor() {
        _setOwner(msg.sender);
    }

    /**@dev Throws if called by any account other than the owner */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /** 
    * @dev Allows the current owner to transfer control of the contract to a newOwner
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Not transferred to zero address");
        emit OwnershipTransferred(owner, newOwner);
    }
    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}

// File: contracts/Marketplace.sol

pragma solidity >=0.8.5;

contract Marketplace is Ownable {

    uint256 public listingId;
    address tokenAddress;

    struct TokenListing {
        address seller;
        address tokenAddress;
        uint256 price;
        bool isStake;
    }

    mapping(uint256 => TokenListing) public listings;

    event TokenStaked(
    uint256 indexed tokenId,
    address indexed tokenAddress,
    address indexed staker
    );

    event TokenPurchased(
    uint256 indexed tokenId,
    address indexed tokenAddress,
    uint256 price,
    address indexed seller,
    address buyer
    );

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function listTokenForSale(uint256 amount) public returns (uint256) {
        require(amount > 0, "Price should be greater than zero");

        uint256 newListingId = listingId;
        TokenListing storage listingDetail = listings[newListingId];
        listingDetail.seller = msg.sender;
        listingDetail.price = amount;
        listingDetail.isStake = false;

        listingId++;
        return newListingId;
    }

    function listTokenForStake(uint256 amount) public returns (uint256) {
        uint256 newListingId = listingId;

        TokenListing storage listingDetail = listings[newListingId];
        listingDetail.seller = msg.sender;
        listingDetail.price = amount;
        listingDetail.isStake = true;

        listingId++;
        return newListingId;
    }

    function purchaseToken(uint256 tokenId) public payable {
    TokenListing storage listingDetail = listings[tokenId];
    require(listingDetail.tokenAddress != address(0), "Invalid token listing");

    if (listingDetail.isStake) {
        require(listingDetail.price == 0, "Token is listed for stake, not for sale");
        require(Token(listingDetail.tokenAddress).balanceOf(msg.sender) == 0, "You already have staked tokens");

        // Stake tokens
        Token(listingDetail.tokenAddress).transferFrom(msg.sender, address(this), 1);
        // Perform stake logic
        
        // Emit an event or perform additional actions
        emit TokenStaked(tokenId, listingDetail.tokenAddress, msg.sender);
    } else {
        require(listingDetail.price > 0, "Token is listed for sale, not for stake");
        require(msg.value == listingDetail.price, "Incorrect payment amount");

        // Transfer tokens to the buyer
        TransferHelper.safeTransferFrom(
            listingDetail.tokenAddress,
            listingDetail.seller,
            msg.sender,
            1
        );
        // Emit an event or perform additional actions
        emit TokenPurchased(tokenId, listingDetail.tokenAddress, listingDetail.price, listingDetail.seller, msg.sender);
    }

    // Remove the listing after successful purchase
    delete listings[tokenId];
}

}