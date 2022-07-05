// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IERC20Template.sol";

contract FixPrice {
    address public nvg8_token;
    uint8 public nvg8_decimals;
    address public nvg8_marketplace;
    address public nvg8_factory;
    struct Listing {
        address erc20Token;
        address erc721Token;
        uint256 tokensPerUnit; // nvg8 tokens per unit of data token with decimals //1 token = 1*10**18 //0.5 token = 5*10**17
    }

    mapping(uint256 => Listing) public listings;

    //Modifier only Marketplace
    modifier onlyMarketplace() {
        require(msg.sender == nvg8_marketplace, "Only Marketplace can do this");
        _;
    }

    //Modifier only Factory
    modifier onlyFactory() {
        require(msg.sender == nvg8_factory, "Only Factory can do this");
        _;
    }
    
    // Constructor
    constructor(address _nvg8_token, address _nvg8_factory, address _nvg8_marketplace) {
        require(_nvg8_token != address(0), "Nvg8 token address cannot be 0");
        nvg8_token = _nvg8_token;
        nvg8_factory = _nvg8_factory;
        nvg8_marketplace = _nvg8_marketplace;
        nvg8_decimals = 18; // ? should it be retrieved from nvg8_token?
        //? nvg8_decimals = IERC20Template(_nvg8_token).decimals();
    }

    
    function buyToken(uint256 _dataToken, uint256 _amount, address _owner, address _buyer) public onlyMarketplace returns (bool _success) {
        require(listings[_dataToken].erc20Token != address(0), "ERC20 token address cannot be 0");
        require(_amount > 0, "Amount must be greater than 0");
        require(listings[_dataToken].tokensPerUnit > 0, "Tokens per unit must be greater than 0");
        require(IERC20Template(listings[_dataToken].erc20Token).balanceOf(_owner) > _amount * 10**18, "Not enough tokens");

        // get decimals of data token
        uint256 decimals = IERC20Template(listings[_dataToken].erc20Token).decimals();
        // calculate amount of nvg8 tokens to buy
        // _amount has 0 decimals & tokensPerUnit has `decimals`
        uint256 _tokens = _amount * listings[_dataToken].tokensPerUnit; // 

        // transfer data tokens to buyer
        _success = IERC20Template(listings[_dataToken].erc20Token).transferFrom(
            _owner,
            _buyer,
            _amount * 10**decimals  
        );
        require(_success, "Failed to transfer data tokens");
        // transfer nvg8 tokens to owner
        _success = IERC20Template(nvg8_token).transferFrom(
            _buyer,
            _owner,
            _tokens
        );
        require(_success, "Failed to transfer nvg8 tokens");
    }

    function addDataToken(address _erc20address, address _erc721Address, uint256 _tokensPerUnit, uint256 _dataTokenId) onlyFactory public {
        require(_erc20address != address(0), "ERC20 address is zero");
        require(_erc721Address != address(0), "ERC721 address is zero");
        require(_tokensPerUnit > 0, "Fixed price is zero");

        listings[_dataTokenId] = Listing(_erc20address, _erc721Address, _tokensPerUnit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
interface IERC20Template is IERC20{
    function initialize(string memory name_, string memory symbol_, address _owner, uint256 _totalSupply) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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