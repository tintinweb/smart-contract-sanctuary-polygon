//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICryptospacefleet {
    function mintTo(address _to, string memory _tokenURI) external;
}

contract MintFactory is Ownable {
    IERC20 private immutable USDC;
    ICryptospacefleet private immutable CSF;

    // Freezes functions in the contract
    bool private frozen;

    // Cost of token
    uint256 private price;

    // Address where stables are sent to
    address private payout;

    // Contract Identifier
    string private category;
    /**
        Stores CID for each node in list
     */
    string[] private cids;

    event Minted(
        address indexed payer,
        uint256 indexed price,
        uint256 indexed amount,
        string category
    );

    constructor(
        address _payout,
        string memory _category,
        address _USDC,
        address _CSF
    ) {
        payout = _payout;
        category = _category;
        USDC = IERC20(_USDC);
        CSF = ICryptospacefleet(_CSF);
    }

    modifier isFrozen() {
        require(!frozen, "Function is frozen!");
        _;
    }

    function freeze() external onlyOwner {
        frozen = true;
    }

    function unfreeze() external onlyOwner {
        frozen = false;
    }

    function getPrice() public view returns (uint256) {
        return price * 10**6;
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Invalid argument!");
        price = _price;
    }

    function getWallet() external view returns (address) {
        return payout;
    }

    function setWallet(address _payout) external onlyOwner {
        require(_payout != address(0), "Invalid address!");
        payout = _payout;
    }

    function getCID(uint256 id)
        external
        view
        onlyOwner
        returns (string memory)
    {
        require(0 <= id && id < totalSupply(), "Invalid id");
        return cids[id];
    }

    function addCID(string memory cid) public onlyOwner {
        require(bytes(cid).length != 0, "Invalid string!");
        cids.push(cid);
    }

    function addCIDs(string[] memory _cids) external onlyOwner {
        require(_cids.length != 0, "Invalid string!");
        for (uint256 i = 0; i < _cids.length; i++) {
            addCID(_cids[i]);
        }
    }

    function removeCID(uint256 id) external onlyOwner {
        _remove(id);
    }

    function _remove(uint256 i) internal {
        require(0 <= i && i < cids.length, "Error: Out of bounds!");
        cids[i] = cids[cids.length - 1];
        cids.pop();
    }

    function totalSupply() public view returns (uint256) {
        return cids.length;
    }

    function mint(uint256 amount) external isFrozen {
        uint256 _total = totalSupply();
        require(0 < amount && amount <= _total, "Insufficient amount!");
        uint256 _price = getPrice();
        uint256 totalCost = amount * _price;
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        if (allowance > totalCost) {
            revert("Allowance to high");
        }
        require(allowance == totalCost, "Insufficient allowance!");
        bool success = USDC.transferFrom(msg.sender, payout, allowance);

        require(success, "Error: Invalid transfer!");
        // First hash to pseudo-randomnly select token
        bytes32 hashValue = keccak256(
            abi.encodePacked(
                msg.sender,
                blockhash(block.number - 1),
                block.number,
                amount
            )
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 rand = uint256(hashValue) % totalSupply();
            string memory tokenURI = cids[rand];
            CSF.mintTo(msg.sender, tokenURI);
            _remove(rand);
            //Further hashing involves previous token CID to further spread entropy
            hashValue = keccak256(abi.encodePacked(hashValue, tokenURI));
        }
        emit Minted(msg.sender, price, amount, category);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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