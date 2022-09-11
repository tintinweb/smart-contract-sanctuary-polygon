// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.16;

import "../tokens/ERC2055/ERC2055.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Pricing.sol";
import "./LibMath.sol";


contract LabzERC2055 is ERC2055, Pricing, LibMath, ReentrancyGuard  {

    address public multiSignatureWallet;
    bool internal canSell;
    bool internal canBuy;
    bool internal vipSale;
    uint256 internal vipSupply;
    uint256 public lockDuration;
    mapping(address => uint256) internal _lastBuyTime;
    mapping(address => bool) internal _vipHolders;
    mapping(address => bool) internal _isUnlocked;
    mapping(address => uint256) public lockedBalance;

    constructor() ERC2055("AKX3 LABZ", "LABZ") {
        setTotalSupply(0);
        setMaxSupply(300000000000 * 1e18);
        multiSignatureWallet = msg.sender;
        if(block.chainid == 137 || block.chainid == 80001) {
        setPrice(BASE_PRICE_MATIC, getChainID());
        }
        vipSupply = 6000000000 * 1e18;
        lockDuration = 90 days;
        canBuy = false;
        vipSale = true;
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function currentPrice() public  returns(uint256) {
        return getPrice(block.chainid);
    }

    function buy() external nonReentrant payable {
        require(canBuy == true, "LABZ: cannot buy yet");
        uint256 _val = msg.value;
        address _sender = msg.sender;
        require(_sender != address(0), "LABZ: transfer _sender the zero address");
        uint256 qty = calculateTokenQty(_val);
        uint256 fee = calculateFee(qty * 1e18) * 1e18;
        uint256 toSender = (qty * 1e18) - fee;
        uint256 toMulti = fee;
        safeMint(toSender, _sender);
        safeMint(toMulti, multiSignatureWallet);
    }

    function transfer(address to, uint256 amount) public override nonReentrant returns(bool) {
        if(verifySellPermissions(msg.sender, amount) != true && to != multiSignatureWallet) {
        revert("LABZ: cannot transfer yet");
        }
        return safeTransferToken(address(this), to, amount);
    }

    /** VIP SALE FUNCTIONS **/

    function buyVip(address _sender, uint256 _val) external nonReentrant {
        if(vipSale != true) {
            revert("LABZ: vip sale is over");
        }
        if(totalSupply() == vipSupply) {
            closeSale();
        }
        uint256 qty = calculateTokenQty(_val);
        if(qty <= 0) {
            revert("you need to send value > 0");
        }
        uint256 fee = calculateFee(qty * 1e18) * 1e18;
        uint256 toSender = (qty * 1e18) - fee;
        /*
        @notice 10% of the transaction is sent to the gnosis multisignature wallet for the reserve as stated in the Whitepaper
        */
        uint256 toMulti = fee;
        safeMint(toSender, _sender);
        safeMint(toMulti, multiSignatureWallet);
        lockedBalance[_sender] = toSender;
        _lastBuyTime[_sender] = block.timestamp;
    }

    function closeSale() internal {
        vipSale = false; // we close the sale
        canBuy = true; // people can now buy publicly
        canSell = true; // people can sell when their funds are unlocked
    }

    function verifySellPermissions(address _sender, uint256 amount) internal returns(bool) {
        // @notice vip holders funds are locked for 90 days from the time of the last buy they made as stated in the whitepaper
        // @notice this only affects purchase made during the vip sale
        if(_vipHolders[_sender] == true && canSell == true && _lastBuyTime[_sender] + lockDuration > block.timestamp + 25 seconds) {
            lockedBalance[_sender] = 0;
            _isUnlocked[_sender] = true;
        return true;
        } else if(!isHavingAvailableBalance(_sender)) {
            return false;
        } else if(amount > availableBalance(_sender)) {
            return false;
        } else if(_isUnlocked[_sender] == true) {
            return true;
        } else  {
            return canSell;
        }

    }

    function availableBalance(address _sender) public view returns(uint256) {
        uint256 _locked = lockedBalance[_sender];
        uint256 bal = balanceOf(_sender);
        return bal - _locked;
    }

    function isHavingAvailableBalance(address _sender) public view returns(bool) {
        return availableBalance(_sender) > 0;
    }

   

    receive() external payable {}


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

uint constant BASE_PRICE_MATIC = 0.15 ether;
uint constant BASE_FEE_PERCENT = 10000000;
uint constant MANTISSA = 1e6;

abstract contract LibMath {

    function calculateTokenQty(uint256 maticsAmount) public pure returns(uint256) {
        uint256 base = BASE_PRICE_MATIC;
        return maticsAmount / base;
    }

    function calculateFee(uint256 qty) public pure returns(uint256) {
        uint256 base = BASE_FEE_PERCENT;
        uint256 baseQty = MANTISSA;
        return qty * baseQty * base / MANTISSA;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Pricing {

    uint256 internal mantissa;


    struct Price {
        uint currentValue;
        uint lastValue;
    }

    struct PricingStorage {
        mapping(uint256 => Price) _chainPrice;
    }

    bytes32 internal constant PRICING_STORAGE_ID = keccak256("akx.ecosystem.labz.pricing.storage");


    event PriceSet(uint256 priceForOne, uint256 chainId);
    event PriceUpdated(uint256 lastPrice, uint256 priceForOne, uint256 chainId);

    function pricingStorage() internal pure returns(PricingStorage storage ps) {
        bytes32 position = PRICING_STORAGE_ID;
        assembly {
            ps.slot := position
        }
    }

    function setPrice(uint priceForOne, uint256 chainId) internal {
        PricingStorage storage ps = pricingStorage();
        ps._chainPrice[chainId] = Price(priceForOne, 0);
        emit PriceSet(priceForOne, chainId);
    }

    function getPrice(uint256 chainId) internal view  returns(uint) {
        PricingStorage storage ps = pricingStorage();
        uint256 p = ps._chainPrice[chainId].currentValue;
        return p;
    }

    function updatePrice(uint256 chainId, uint256 newPrice) internal {
        PricingStorage storage ps = pricingStorage();
        uint256 old = getPrice(chainId);
        ps._chainPrice[chainId] = Price(newPrice, old);
        emit PriceUpdated(old, newPrice, chainId);
    }




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC2055Storage.sol";
import "./IERC2055.sol";

contract ERC2055 is IERC2055 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    uint256 public maxSupply;
    address public owner;
    bool public isLocked;
    uint256 public lockedUntil;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    bytes4 private constant TOKEN_INTERFACE_ID =
        bytes4(keccak256(abi.encodePacked("supportedTokenInterfaces(bytes4)")));

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        decimals = 18;
    }

    function feeEstimate(uint256 amount) external view returns(uint256) {
        //@todo implement feeEstimate
        return 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can do this");
        _;
    }

    function setTotalSupply(uint256 supply) public onlyOwner {
        _totalSupply = supply;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        maxSupply = supply;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address to, uint256 amount)
        public
        override
    virtual
        returns (bool)
    {
        this.safeTransferToken(address(this), to, amount);
        return true;
    }



    function approve(address spender, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        _approve(address(this), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
       _transfer(from, to, amount);
       return true;
    }

      /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address _owner = owner;
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }

     function allowance(address _owner, address spender) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }


    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address _owner = owner;
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

  
     function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

 function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");


        uint256 fromBalance = _balance[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balance[from] = fromBalance - amount;
        }
        _balance[to] += amount;

        emit Transfer(from, to, amount);

     
    }



    function safeMint(uint256 amount, address to)
        public
     
        onlyOwner
        returns (bool)
    {
        if (amount > maxSupply) {
            revert("amount is higher than the max supply (CAP)");
        }
        if (amount == 0) {
            revert("amount cannot be zero");
        }

        if (_totalSupply == 0) {
            _totalSupply = amount;
        } else {
            _totalSupply += amount;
        }
        if (_balance[to] == 0) {
            _balance[to] = amount;
        } else {
            _balance[to] += amount;
        }
        return true;
    }



    function safeTransferToken(
        address token,
        address receiver,
        uint256 amount
    ) public virtual override returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(
            0xa9059cbb,
            receiver,
            amount
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(
                sub(gas(), 10000),
                token,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0x20
            )
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }

    function lockToken(uint256 until) public override onlyOwner {
        require(isLocked != true, "already locked");
        isLocked = true;
        lockedUntil = until;
    }

    function unlockToken() public override {
        if (block.timestamp > lockedUntil) {
            revert("cannot unlock");
        }
        isLocked = false;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC2055.sol";


abstract contract ERC2055Storage {
    mapping(uint256 => address) internal _tokenIdtoAddresses;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public names;
    mapping(uint256 => string) public symbols;
    mapping(uint256 => uint256) public supply;
    mapping(uint256 => uint8) public _decimals;
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(address => mapping(uint256 => Balances[])) internal _tokenBalances;
    mapping(uint256 => mapping(address => uint256)) public allowances;
    mapping(address => uint256[]) public _holdsTokenIds;
    mapping(uint256 => Token) internal _tokens;
    mapping(uint256 => OptionalTokenMetas) private _optionalMetas;
    mapping(uint256 => bool) internal _hasMetas;
    mapping(uint256 => ERC2055) internal _underlyings;
    uint256[] internal _tokenIds;

    struct Balances {
        address owner;
        address token;
        uint256 tokenId;
        uint256 amount;
    }

    struct Token {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 maxSupply;
        uint8 decimals;
    }

    struct OptionalTokenMetas {
        string logoUri;
        string website;
        string whitepaper;
        string[] socialLinks;
        address[] founders;
        address[] sponsors;
        string[] akas;
        string[] networks;
        uint256[] chainIds;
    }

    function tokenIds() public view returns(uint256[] memory) {
        return _tokenIds;
    }

    function balancesOf(address holder) external view returns(Balances[] memory) {
        uint i = 0;
        Balances[] memory b;
        for(i == 0; i < _holdsTokenIds[holder].length; i+=1) {
            uint256 tid = _holdsTokenIds[holder][i];
            b[i] = Balances(holder, _tokenIdtoAddresses[tid],tid, _balances[tid][holder]);
        }
        return b;
    }

    function token(uint256 tokenId) external view returns (Token memory) {
        return _tokens[tokenId];
    }

    function _tName(uint256 tokenId)  external view returns (string memory) {
        return this.token(tokenId).name;
    }

    function _tSymbol(uint256 tokenId) external view returns (string memory) {
         return this.token(tokenId).symbol;
    }

    function _tDecimal(uint256 tokenId) external view returns (uint8) {
         return this.token(tokenId).decimals;
    }


    function _tTotalSupply(uint256 tokenId) external view returns (uint256) {
         return this.token(tokenId).totalSupply;
    }

    function _tMaxSupply(uint256 tokenId) external view returns (uint256) {
         return this.token(tokenId).maxSupply;
    }

    function metas(uint256 tokenId) external view returns(OptionalTokenMetas memory opts) {
     
       string[] memory socials;
       address[] memory founders;
       address[] memory sponsors;
       string[] memory akas;
       string[] memory networks;
       uint256[] memory chainIds;

        if(_hasMetas[tokenId] != true) {
        opts = OptionalTokenMetas(
            "",
            "",
            "",
            socials,
            founders,
            sponsors,
            akas,
            networks,
            chainIds);
        } else {
            opts = _optionalMetas[tokenId];
        }

    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC2055 is IERC20 {

    function safeTransferToken(address from, address to, uint256 amount) external returns(bool transferred);
    function lockToken(uint256 until) external;
    function unlockToken() external;
    function feeEstimate(uint256 amount) external view returns(uint256);

}