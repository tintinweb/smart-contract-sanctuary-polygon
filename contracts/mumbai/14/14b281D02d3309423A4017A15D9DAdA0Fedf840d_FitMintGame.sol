pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "Ownable.sol";

interface FitMintToken {
    function mintTokens(uint256 tokenAmount) external;
}

interface FitMintNFT {
    function mintNFT(address userAddress) external;
}

contract FitMintGame is Ownable {

    address public tokenAddress;
    address public nftAddress;
    FitMintToken gameTokenInstance;
    FitMintNFT gameNFTInstance;

    bool public isAllowListActive = false;
    mapping(address => uint8) _allowList;
    uint256 public pricePerNFT = 50 ether;

    constructor(address _tokenAddress, address _nftAddress) public {
        tokenAddress = _tokenAddress;
        gameTokenInstance = FitMintToken(_tokenAddress);
        gameNFTInstance = FitMintNFT(_nftAddress);
    }

    function setTokenAddr(address _tokenAddress) public onlyOwner {
       tokenAddress = _tokenAddress;
       gameTokenInstance = FitMintToken(_tokenAddress);
    }

    function setNFTAddr(address _nftAddress) public onlyOwner {
       nftAddress = _nftAddress;
       gameNFTInstance = FitMintNFT(_nftAddress);
    }

    function setPricePerNFT(uint256 _pricePerNFT) public onlyOwner {
       pricePerNFT = _pricePerNFT * 10^18;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function claimComminityTokens(uint tokenAmount) public onlyOwner{
        gameTokenInstance.mintTokens(tokenAmount);
    }
    

    function claimNFTwithPolygon() public payable{
        require(isAllowListActive, "Allow list is not active");
        require(msg.value >= pricePerNFT);
        require(_allowList[msg.sender] > 0);
        gameNFTInstance.mintNFT(msg.sender);
        _allowList[msg.sender] -= 1;
    }
}

// function mintAllowList(uint8 numberOfTokens) external payable {
    //     uint256 ts = totalSupply();
    //     require(isAllowListActive, "Allow list is not active");
    //     require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
    //     require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
    //     require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

    //     
    //     for (uint256 i = 0; i < numberOfTokens; i++) {
    //         _safeMint(msg.sender, ts + i);
    //     }
    // }

    // function changeAttributes(address _userAddress, uint256 _userTokenBalance) public onlyOwner {
    //     userAccount[_userAddress].tokenBalance = _userTokenBalance;
    // }
// contract FitMintGame is Ownable {
//     struct Payment {
//         uint amount;
//         uint timestamp;
//     }
//     address MaticToken;
//     struct Balance {
//         uint totalBalance;
//         uint numPayments;
//         mapping(uint => Payment) payments;
//     }

//     address [] invetory_tokens;
//     mapping(address => mapping(address => Balance)) public balanceReceived;

//     event InventoryTxn(address _address, uint _amount, uint _type, address _tokenName);
//     enum InventoryTxnType {Credit, Debit}

//     function getBalance() public view returns (uint) {
//         return address(this).balance;
//     }


//     function sendMoney() public payable {

//         balances[msg.sender].totalBalance += msg.value;
//         Payment memory payment = Payment(msg.value, block.timestamp);
//         balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
//         balanceReceived[msg.sender].numPayments++;
//         // emit InventoryTxn(msg.sender,msg.value,InventoryTxnType.Credit,);
//     }

//     function addEarning(address beneficiary, uint amount) public onlyOwner {
//         balances[msg.sender].totalBalance += msg.value;
//         Payment memory payment = Payment(msg.value, block.timestamp);
//         balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
//         balanceReceived[msg.sender].numPayments++;
//     }

//     function withdrawMoney(address payable _to, uint _amount) public {
//         require(_amount <= balanceReceived[msg.sender].totalBalance, "not enough funds");
//         balanceReceived[msg.sender].totalBalance -= _amount;
//         _to.transfer(_amount);
//     }

//     function withdrawAllMoney(address payable _to) public {
//         uint balanceToSend = balanceReceived[msg.sender].totalBalance;
//         balanceReceived[msg.sender].totalBalance = 0;
//         _to.transfer(balanceToSend);
//     }

// }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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