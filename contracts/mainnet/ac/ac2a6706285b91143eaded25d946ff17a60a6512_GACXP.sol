/**
 *Submitted for verification at polygonscan.com on 2022-06-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IGACXP.sol



pragma solidity ^0.8.10;


/**
 * Author: Cory Cherven (Animalmix55/ToxicPizza)
 */
interface IGACXP is IERC20 {
    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external;

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to) external;

    /**
     * Burns the given amount for the user provided the sender is authorized.
     */
    function burn(address from, uint256 amount) external;

    /**
     * Gets the amount of mints the user is entitled to.
     */
    function getMintAllowance(address user) external view returns (uint256);

    /**
     * Updates the allowance for the given user to mint. Set to zero to revoke.
     *
     * @dev This functionality programatically enables allowing other platforms to
     *      distribute the token on our behalf.
     */
    function updateMintAllowance(address user, uint256 amount) external;
}

// File: @rari-capital/solmate/src/tokens/ERC20.sol


pragma solidity >=0.8.0;


/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 is IERC20 {
    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/access/DeveloperAccess.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an developer) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the developer account will be the one that deploys the contract. This
 * can later be changed with {transferDevelopership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDeveloper`, which can be applied to your functions to restrict their use to
 * the developer.
 */
abstract contract DeveloperAccess is Context {
    address private _developer;

    event DevelopershipTransferred(address indexed previousDeveloper, address indexed newDeveloper);

    /**
     * @dev Initializes the contract setting the deployer as the initial developer.
     */
    constructor(address dev) {
        _setDeveloper(dev);
    }

    /**
     * @dev Returns the address of the current developer.
     */
    function developer() public view virtual returns (address) {
        return _developer;
    }

    /**
     * @dev Throws if called by any account other than the developer.
     */
    modifier onlyDeveloper() {
        require(developer() == _msgSender(), "Ownable: caller is not the developer");
        _;
    }

    /**
     * @dev Leaves the contract without developer. It will not be possible to call
     * `onlyDeveloper` functions anymore. Can only be called by the current developer.
     *
     * NOTE: Renouncing developership will leave the contract without an developer,
     * thereby removing any functionality that is only available to the developer.
     */
    function renounceDevelopership() public virtual onlyDeveloper {
        _setDeveloper(address(0));
    }

    /**
     * @dev Transfers developership of the contract to a new account (`newDeveloper`).
     * Can only be called by the current developer.
     */
    function transferDevelopership(address newDeveloper) public virtual onlyDeveloper {
        require(newDeveloper != address(0), "Ownable: new developer is the zero address");
        _setDeveloper(newDeveloper);
    }

    function _setDeveloper(address newDeveloper) private {
        address oldDeveloper = _developer;
        _developer = newDeveloper;
        emit DevelopershipTransferred(oldDeveloper, newDeveloper);
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/GACXP.sol



pragma solidity ^0.8.10;






/**
 * The official on-chain GACXP token meant to be hosted on Polygon (MATIC)
 *
 * Author: Cory Cherven (Animalmix55/ToxicPizza)
 */
contract GACXP is ERC20, IGACXP, Ownable, DeveloperAccess, ReentrancyGuard {
    bool public mintingPaused;

    /**
     * A mapping of addresses to mint allowances. For granting other communities the right to mint.
     */
    mapping(address => uint256) private _mintAllowance;

    constructor(address devAddress)
        ERC20("GACXP", "GACXP", 18)
        DeveloperAccess(devAddress)
    {}

    // -------------------------------------------- OWNER/DEV ONLY ----------------------------------------

    /**
     * @dev Throws if called by any account other than the developer/owner.
     */
    modifier onlyOwnerOrDeveloper() {
        require(
            developer() == _msgSender() || owner() == _msgSender(),
            "Ownable: caller is not the owner or developer"
        );
        _;
    }

    /**
     * Updates the allowance for the given user to mint. Set to zero to revoke.
     *
     * @dev This functionality programatically enables allowing other platforms to
     *      distribute the token on our behalf.
     */
    function updateMintAllowance(address user, uint256 amount)
        external
        onlyOwnerOrDeveloper
    {
        _mintAllowance[user] = amount;
    }

    /**
     * Pauses or resumes minting. Good for stopping all mints.
     */
    function setMintingPaused(bool paused) external onlyOwnerOrDeveloper {
        mintingPaused = paused;
    }

    // -------------------------------------------- PUBLIC -------------------------------------------------

    /**
     * Mints to the given account from the sender provided the sender is authorized.
     */
    function mint(uint256 amount, address to) external nonReentrant {
        require(
            !mintingPaused ||
                msg.sender == owner() ||
                msg.sender == developer(),
            "Minting paused"
        );

        _reduceMintAllowance(msg.sender, amount);
        _mint(to, amount);
    }

    /**
     * Mints to the given accounts from the sender provided the sender is authorized.
     */
    function bulkMint(uint256[] calldata amounts, address[] calldata to)
        external
        nonReentrant
    {
        require(
            !mintingPaused ||
                msg.sender == owner() ||
                msg.sender == developer(),
            "Minting paused"
        );
        require(amounts.length == to.length, "Length mismatch");
        uint256 totalMinted;

        for (uint256 i; i < amounts.length; i++) {
            totalMinted += amounts[i]; // fails on underflow
            _mint(to[i], amounts[i]);
        }

        _reduceMintAllowance(msg.sender, totalMinted);
    }

    /**
     * Burns the given amount for the user provided the sender is authorized.
     */
    function burn(address from, uint256 amount) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (from != msg.sender && allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount; // fails on underflow

        _burn(from, amount);
    }

    /**
     * Gets the amount of mints the user is entitled to.
     */
    function getMintAllowance(address user) external view returns (uint256) {
        return _getMintAllowance(user);
    }

    // -------------------------------------------- INTERNAL -----------------------------------------------

    /**
     * Returns the amount of tokens the user is allowed to mint.
     */
    function _getMintAllowance(address user) internal view returns (uint256) {
        if (user == developer() || user == owner()) return type(uint256).max;

        return _mintAllowance[user];
    }

    /**
     * Reduces the amount of tokens the user is allowed to mint.
     * @dev does nothing for dev/owner. Does nothing if allowance is max.
     */
    function _reduceMintAllowance(address user, uint256 amount) internal {
        if (user == developer() || user == owner()) return;
        if (_mintAllowance[user] == type(uint256).max) return;

        _mintAllowance[user] -= amount;
    }
}