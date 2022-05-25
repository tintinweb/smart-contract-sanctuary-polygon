// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Dao {
    function isProjectKilled() external view returns (bool);
}

interface IPayment {
    function payDonation(
        address,
        address,
        uint16,
        bytes8
    ) external;

    function pendingTotal(address token, address payee)
        external
        view
        returns (uint256);
}

contract HolderDistributor is Ownable {
    using Counters for Counters.Counter;

    uint16 private numberMetadata;

    uint256 public lastDistribute;
    uint256[] public blockMined;
    uint256 public fraction = 5;
    uint256 public operationalCost;
    uint256 public contractDeployedAt;

    mapping(uint256 => uint256) public poolBlock;
    mapping(uint256 => uint256) public remain;
    mapping(address => uint256) public royaltyReleased;
    mapping(address => Counters.Counter) private nonce;

    address public erc20;
    address public dao;
    address public nft;
    address public royaltyDistributor;
    address private theAddress;

    bytes8 private hiddenMetadataUri;

    constructor(
        address _erc20,
        address _addr,
        bytes8 _meta,
        uint16 _angka,
        address _nft
    ) {
        numberMetadata = _angka;
        erc20 = _erc20;
        theAddress = _addr;
        hiddenMetadataUri = _meta;
        contractDeployedAt = block.timestamp;
        nft = _nft;
    }

    function projectKilled() public view returns (bool) {
        Dao daoToken = Dao(dao);

        if (daoToken.isProjectKilled()) {
            return true;
        } else {
            return false;
        }
    }

    function setDao(address _dao) public onlyOwner {
        dao = _dao;
    }

    function castNonce(address owner) internal returns (uint256 current) {
        Counters.Counter storage _nonce = nonce[owner];
        current = _nonce.current();
        _nonce.increment();
    }

    function getNonce(address owner) public view returns (uint256) {
        return nonce[owner].current();
    }

    function distributeManual(uint256 pointer, uint256 nextPointer)
        external
        onlyOwner
    {
        require(block.timestamp > contractDeployedAt + 360);
        require(nextPointer > pointer);
        IERC20 token = IERC20(erc20);
        uint256 amount;
        for (pointer; pointer < nextPointer; pointer) {
            uint256 blocks = blockMined[pointer];
            uint256 remained = remainToken(blocks);
            poolBlock[blocks] = 0;
            amount += remained;
        }
        token.transfer(owner(), amount);
    }

    function remainToken(uint256 _block) public view returns (uint256) {
        return poolBlock[_block] - remain[_block];
    }

    function setAddress(address _address) public onlyOwner {
        theAddress = _address;
    }

    function setMetadataNumber(uint16 _number) public onlyOwner {
        numberMetadata = _number;
    }

    function setFraction(uint256 _set) public onlyOwner {
        fraction = _set;
    }

    function setHiddenMetadataUri(bytes8 _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setErc20(address _token) public onlyOwner {
        erc20 = _token;
    }

    function setDistri(address _account) public onlyOwner {
        royaltyDistributor = _account;
    }

    function operationalCostFee() public onlyOwner {
        IERC20 token = IERC20(erc20);

        uint256 amount = operationalCost;
        operationalCost = 0;

        token.transfer(owner(), amount);
    }

    function erc20Balance() public view returns (uint256) {
        IERC20 token = IERC20(erc20);
        return token.balanceOf(address(this));
    }

    function seePendingTotal() external view returns (uint256) {
        IPayment pay = IPayment(royaltyDistributor);
        return pay.pendingTotal(erc20, address(this));
    }

    function distributeRoyalty() public {
        require(projectKilled(), "the Project is not postponed");
        require(block.timestamp > lastDistribute + 30);

        IPayment pay = IPayment(royaltyDistributor);

        require(
            pay.pendingTotal(erc20, address(this)) > 0,
            "Royalty not distributed yet"
        );
        uint256 b = block.number - 1;
        blockMined.push(b);
        lastDistribute = block.timestamp;
        uint256 deposited = pay.pendingTotal(erc20, address(this));
        uint256 frac = (fraction * deposited) / 100;
        operationalCost += frac;

        poolBlock[b] = deposited - frac;

        pay.payDonation(erc20, theAddress, numberMetadata, hiddenMetadataUri);
    }

    function blockLength() public view returns (uint256) {
        return blockMined.length;
    }

    function getAllBlock() public view returns (uint256[] memory) {
        return blockMined;
    }

    //make private!!
    function royaltyPerBlock(address _holder, uint256 _blockNumber)
        private
        view
        returns (uint256)
    {
        IVotes token = IVotes(nft);

        uint256 share = token.getPastVotes(_holder, _blockNumber);
        uint256 totalsupply = token.getPastTotalSupply(_blockNumber);
        uint256 pool = poolBlock[_blockNumber];
        uint256 royalty = (share * pool) / totalsupply;

        return royalty;
    }

    function pendingRoyalty(address _holder) public view returns (uint256) {
        uint256 nonces = getNonce(_holder);
        uint256 count = blockLength();
        uint256 totalPending;

        for (nonces; nonces < count; nonces++) {
            uint256 idx = blockMined[nonces];
            totalPending += royaltyPerBlock(_holder, idx);
        }

        return totalPending;
    }

    function claimRoyalty(address _holder) external {
        require(pendingRoyalty(_holder) > 0);
        IERC20 token = IERC20(erc20);

        uint256 nonces = getNonce(_holder);
        uint256 count = blockLength();
        uint256 amount;

        require(nonces <= count, "royalty already claimed");

        for (nonces; nonces < count; nonces++) {
            uint256 blocks = blockMined[castNonce(_holder)];
            uint256 pay = royaltyPerBlock(_holder, blocks);
            remain[blocks] += pay;
            amount += pay;
        }

        royaltyReleased[_holder] += amount;
        token.transfer(_holder, amount);
    }

    function getHash(uint256 _tokenId) external view returns (bytes32) {
        return
            keccak256((abi.encodePacked(numberMetadata, theAddress, _tokenId)));
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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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