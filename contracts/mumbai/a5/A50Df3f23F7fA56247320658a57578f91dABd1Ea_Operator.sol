// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// interface IHouseBusiness {
//     function setPayable(uint256 tokenId, address _buyer, bool nftPayable) external;

//     function mintHouse(
//         string memory _name,
//         string memory _tokenURI,
//         string memory _tokenType,
//         string memory initialDesc
//     ) external payable;

//     function addHistory(
//         uint256 _tokenId,
//         uint256 contractId,
//         uint256 newHistoryType,
//         string memory houseImg,
//         string memory houseBrand,
//         string memory _history,
//         string memory _desc,
//         string memory brandType,
//         uint256 yearField
//     ) external;

//     function editHistory(
//         uint256 _tokenId,
//         uint256 historyIndex,
//         string memory houseImg,
//         string memory houseBrand,
//         string memory _history,
//         string memory _desc,
//         string memory brandType,
//         uint256 yearField
//     ) external;

//     function addOrEditHType(
//         uint256 _historyIndex,
//         string memory _label,
//         bool _connectContract,
//         bool _imgNeed,
//         bool _brandNeed,
//         bool _descNeed,
//         bool _brandTypeNeed,
//         bool _yearNeed,
//         bool _checkMark
//     ) external;

//     function removeHistoryType(uint256 _hIndex) external;

//     // Disconnects contract from house history.
//     function disconnectContract(uint256 tokenId, uint256 hIndex, uint256 contractId) external;

//     function buyHouseNft(uint256 tokenId) external payable;

//     function changeHousePrice(uint256 tokenId, uint256 newPrice) external;
// }

// interface IMainCleanContract {
//     // write Contract
//     function ccCreation(
//         string memory _companyName,
//         string memory _contractType,
//         address _contractSigner,
//         string memory _contractURI,
//         uint256 _dateFrom,
//         uint256 _dateTo,
//         uint256 _agreedPrice,
//         string memory _currency
//     ) external;

//     // Add Contract Signer
//     function addContractSigner(uint256 _ccID, address _contractSigner) external;

//     // sign contract
//     function signContract(uint256 ccID) external;

//     // send sign notification
//     function sendNotify(address _notifyReceiver, string memory _notifyContent, uint256 ccID) external;

//     /**
//      * @dev modifies ownership of `contractId` from `from` to `to`
//      */
//     function transferContractOwnership(uint256 contractId, address from, address to) external;
// }

// interface IHouseBusinessToken {
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

//     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
// }

contract Operator is Ownable {
    // Contract addresses
    IERC20 HBToken;
    
    // IHouseBusiness HouseBusiness;
    // IMainCleanContract CContract;

    // Token balances that can be used as gas fee from the account users
    mapping(address => uint256) private _balances;

    // Authorized contract addresses which will be called from this contract
    mapping(address => bool) private _authorizedContracts;

    // Utility tokens and NFT address
    address houseBusinessToken;

    // address houseBusiness = 0x0A964d282AF35e81Ad9d72e5c215108B3c43D3c1;
    // address cContract = 0xaa3Dc2E3ca0FE2dE6E519F0F224456861A7e9cFC;

    constructor(address _houseBusinessToken) {
        // Init contract instances
        HBToken = IERC20(houseBusinessToken);

        // HouseBusiness = IHouseBusiness(houseBusiness);
        // CContract = IMainCleanContract(cContract);
    }

    // /**
    //  * Provides the ability to update smart contract addresses for scalability.
    //  * @param _houseBusiness HouseBusiness NFT address
    //  */
    // function setHouseBusiness(address _houseBusiness) external onlyOwner {
    //     houseBusiness = _houseBusiness;
    //     HouseBusiness = IHouseBusiness(_houseBusiness);
    // }

    // /**
    //  * Provides the ability to update smart contract addresses for scalability.
    //  * @param _cContract MainCleanContract address
    //  */
    // function setCContract(address _cContract) external onlyOwner {
    //     cContract = _cContract;
    //     CContract = IMainCleanContract(_cContract);
    // }

    /**
     * Provides the ability to update smart contract addresses for scalability.
     * @param _houseBusinessToken HouseBusinessToken address
     */
    function setHBToken(address _houseBusinessToken) external onlyOwner {
        houseBusinessToken = _houseBusinessToken;
        HBToken = IERC20(_houseBusinessToken);
    }

    function authorizeContract(address contractAddress) external onlyOwner {
        _authorizedContracts[contractAddress] = true;
    }

    function revokeContract(address contractAddress) external onlyOwner {
        _authorizedContracts[contractAddress] = false;
    }

    function isContractAuthorized(address contractAddress) external view returns (bool) {
        return _authorizedContracts[contractAddress];
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // These functions should be called from the account user's virtual wallet address
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(HBToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        _balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        require(HBToken.transfer(msg.sender, amount), "Transfer failed");
        _balances[msg.sender] -= amount;
    }

    function callContract(address contractAddress, bytes memory data, uint256 gasFee) external {
        require(_authorizedContracts[contractAddress], "Contract not authorized");
        require(_balances[msg.sender] >= gasFee, "Insufficient balance");
        require(HBToken.transferFrom(msg.sender, address(this), gasFee), "Transfer failed");
        _balances[msg.sender] -= gasFee;
        (bool success,) = contractAddress.call(data);
        require(success, "Contract call failed");
    }
}