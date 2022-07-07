// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IWhitelist.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

/// @notice : Give all fee related values in 10^8 (1 USDT == 10^8)

/// @dev : TEST RINKEBY DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735
/// @dev : TEST RINKEBY DAI ORACLE = 0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF

/// @dev : TEST MUMBAI USDC = 0xe11a86849d99f524cac3e7a0ec1241828e332c62
/// @dev : TEST MUMBAI USDC ORACLE = 0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0

/// @dev : TEST MUMBAI WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
/// @dev : TEST MUMBAI WMATIC ORACLE = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada

/// @dev : Swap in Uniswap

interface IAddressRegistry {
    function whitelistContract() external view returns (address);
}

contract TreasuryManagement is ReentrancyGuard {
    //-------------------------EVENTS---------------------------//

    event updateAddressRegistryEvent(address newAddress);
    event addTokenSupportEvent(address tokenAddress, address dataOracleAddress);
    event removeTokenSupportEvent(address newAddress);
    event updateMintFeeEvent(uint256 newValue);
    event updatePlatformFeeEvent(uint256 newValue);
    event priceOfToken(int256 newValue);
    event chargeForMintingEvent(uint256 fee, bool status);
    event etherSent(string message);

    //---------------------STATE VARIABLES----------------------//

    /// @notice NFT mint fee in 1s (1 = 1 USD)
    uint256 public mintFee;

    /// @notice Platform fee for deploying new NFT contract in in 1s (1 = 1 USD)
    uint256 public platformFee;

    /// @notice An address source for the contract to interface with whitelist contract
    IAddressRegistry public addressRegistry;

    /// @notice An address source for the contract to send all collected fees to
    address payable public treasuryAddress;

    /// @notice A set of addresses for the contract to interface with other ERC20 tokens on-chain
    address[] public whitelistedTokenAddresses;

    /// @notice Using Interface as Oracle to interact with oracle
    AggregatorV3Interface internal Oracle;

    /// @notice Using Interface of any chosen ERC20 Token
    IERC20 internal token;

    /// @notice A map to track every whitelisted token address to it's respective chainlink datafeed address
    mapping(address => address) public dataFeedSourceAddress;

    /// @notice stores last updated price of whitelisted address
    mapping(address => int256) public lastPriceOfToken;

    //----------------------MODIFIERS--------------------------//

    /// @notice A map to track every whitelisted token address to it's respective chainlink datafeed address
    modifier onlyAdmin() {
        bool hasAdmin = IWhitelist(addressRegistry.whitelistContract())
            .hasRoleAdmin(msg.sender);
        require(hasAdmin, "Not an Admin");
        _;
    }

    /// @notice Checks if user allocated token is whitelisted or not
    modifier isWhitelisted(address _token) {
        require(dataFeedSourceAddress[_token] != address(0), "Not Whitelisted");
        _;
    }

    //----------------------CONSTRUCTOR------------------------//

    /// @notice Set all global values
    constructor(
        address _addressRegistryAddress,
        address[] memory _whitelistedTokenAddresses,
        address[] memory _dataFeedAddresses,
        address payable _treasuryAddress,
        uint256 _mintFee,
        uint256 _platformFee
    ) {
        require(
            _whitelistedTokenAddresses.length == _dataFeedAddresses.length,
            "Please give a data feed for all tokens"
        );
        addressRegistry = IAddressRegistry(_addressRegistryAddress);
        whitelistedTokenAddresses = _whitelistedTokenAddresses;
        for (uint256 i = 0; i < whitelistedTokenAddresses.length; i++) {
            dataFeedSourceAddress[
                whitelistedTokenAddresses[i]
            ] = _dataFeedAddresses[i];
        }
        mintFee = _mintFee;
        treasuryAddress = _treasuryAddress;
        platformFee = _platformFee;
    }

    //-----------------FALLBACK METHODS------------------------//

    fallback() external payable {
        treasuryAddress.transfer(msg.value);
        emit etherSent("The contract does not support direct payments, your Ether has been transferred to Treasury Address");
    }
    receive() external payable {
        treasuryAddress.transfer(msg.value);
        emit etherSent("The contract does not support direct payments, your Ether has been transferred to Treasury Address");
    }

    //-----------------OPERATION METHODS------------------------//

    /// @notice Collects fee in ERC20 token for all minting events
    /// @dev Use the commented function below to test without whitelisting
    /// @param _token takes the ERC20 contract address (make sure it's whitelisted)
    /// @param _sender address which will pay the fee
    /// @return success , fee : returns both status of transaction and fee
    function chargeForMinting(address _token, address _sender)
        public
        isWhitelisted(_token)
        returns (bool success, uint256 _fee)
    {
        require(
            IWhitelist(addressRegistry.whitelistContract()).hasRoleFactory(
                msg.sender
            ),
            "Sender is not a factory or a contract"
        );
        if (
            !IWhitelist(addressRegistry.whitelistContract()).hasRoleAdmin(
                _sender
            )
        ) {
            IERC20 token = IERC20(_token);
            int256 price = getPriceOfTokenByAddress(_token);
            uint256 fee = ((mintFee * 10**8) / uint256(price)) * 10**18;

            require(
                token.balanceOf(_sender) >= fee,
                "Not Enough ERC20 Balance"
            );
            require(
                token.allowance(_sender, address(this)) >= fee,
                "Not Enough Allowance"
            );
            // require(fee);
            token.transferFrom(_sender, treasuryAddress, fee);
            emit chargeForMintingEvent(fee, true);
            return (true, fee);
        } else {
            emit chargeForMintingEvent(0, true);
            return (true, 0);
        }
    }

    /// @notice Collects fee in ERC20 token for all deploying events
    /// @param _token takes the ERC20 contract address (make sure it's whitelisted)
    /// @return success , fee : returns both status of transaction and fee
    function chargeForDeploying(address _token, address _sender)
        public
        isWhitelisted(_token)
        returns (bool success, uint256 _fee)
    {
        require(
            IWhitelist(addressRegistry.whitelistContract()).hasRoleFactory(
                msg.sender
            ),
            "Sender is not a factory or a contract"
        );
        if (
            !IWhitelist(addressRegistry.whitelistContract()).hasRoleAdmin(
                _sender
            )
        ) {
            IERC20 token = IERC20(_token);
            int256 price = getPriceOfTokenByAddress(_token);
            uint256 fee = ((platformFee * 10**8) / uint256(price)) * 10**18;
            require(
                token.balanceOf(_sender) >= fee,
                "Not Enough ERC20 Balance"
            );
            require(
                token.allowance(_sender, address(this)) >= fee,
                "Not Enough Allowance"
            );
            // require(fee);
            token.transferFrom(_sender, treasuryAddress, fee);
            emit chargeForMintingEvent(fee, true);
            return (true, fee);
        } else {
            emit chargeForMintingEvent(0, true);
            return (true, 0);
        }
    }

    //-----------------SET METHODS--------------------//

    /// @notice updates address registry contract address
    function updateAddressRegistry(address _newAddress) public onlyAdmin {
        addressRegistry = IAddressRegistry(_newAddress);
        emit updateAddressRegistryEvent(_newAddress);
    }

    /// @notice Adds new ERC20 token support
    /// @param _tokenAddress takes the ERC20 contract address for whitelisting
    /// @param _OracleAddress takes a price oracle for the given ERC20 token
    function addTokenSupport(address _tokenAddress, address _OracleAddress)
        public
        onlyAdmin
    {
        require(
            dataFeedSourceAddress[_tokenAddress] == address(0),
            "Token Already Exists"
        );
        whitelistedTokenAddresses.push(_tokenAddress);
        dataFeedSourceAddress[_tokenAddress] = _OracleAddress;
        emit addTokenSupportEvent(_tokenAddress, _OracleAddress);
    }

    /// @notice Removes existing ERC20 token support
    /// @param _tokenAddress takes the ERC20 contract address for blacklisting
    function removeTokenSupport(address _tokenAddress) public onlyAdmin {
        require(
            dataFeedSourceAddress[_tokenAddress] != address(0),
            "Token Doesn't Exist"
        );
        dataFeedSourceAddress[_tokenAddress] = address(0);
        uint256 _index = getIndexByToken(_tokenAddress);
        for (
            uint256 i = _index;
            i < whitelistedTokenAddresses.length - 1;
            i++
        ) {
            whitelistedTokenAddresses[i] = whitelistedTokenAddresses[i + 1];
        }
        whitelistedTokenAddresses.pop();
        emit removeTokenSupportEvent(_tokenAddress);
    }

    /// @notice updates universal mint fee
    function updateMintFee(uint256 _value) public onlyAdmin {
        mintFee = _value;
        emit updateMintFeeEvent(mintFee);
    }

    /// @notice updates universal platform fee
    function updatePlatformFee(uint256 _value) public onlyAdmin {
        platformFee = _value;
        emit updateMintFeeEvent(platformFee);
    }

    //-----------------GET METHODS--------------------//

    function getIndexByToken(address _tokenAddress)
        public
        view
        returns (uint256 value)
    {
        for (uint256 i = 0; i < whitelistedTokenAddresses.length; i++) {
            if (whitelistedTokenAddresses[i] == _tokenAddress) {
                return (i);
            }
        }
        revert();
    }

    function getERC20Balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getERC20UserBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(msg.sender);
    }

    function getAllowance(address _token) public view returns (uint256) {
        address sender = msg.sender;
        return IERC20(_token).allowance(sender, address(this));
    }

    function getTokenByIndex(uint256 _index)
        public
        view
        returns (address tokenAddress)
    {
        require(
            _index < whitelistedTokenAddresses.length,
            "Index out of bounds"
        );
        return (whitelistedTokenAddresses[_index]);
    }

    /// @notice Uses the price oracle to retrive the tokenaddress provided.
    function getPriceOfTokenByAddress(address _tokenAddress)
        public
        returns (int256 value)
    {
        Oracle = AggregatorV3Interface(dataFeedSourceAddress[_tokenAddress]);
        (, int256 price, , , ) = Oracle.latestRoundData();
        emit priceOfToken(price);
        return price;
    }

    function getPriceOfTokenByIndex(uint256 _index)
        public
        returns (int256 value)
    {
        return (getPriceOfTokenByAddress(getTokenByIndex(_index)));
    }

    function getOracleByIndex(uint256 _index)
        public
        view
        returns (address tokenAddress)
    {
        return (dataFeedSourceAddress[whitelistedTokenAddresses[_index]]);
    }

    function getOracleByAddress(address _token)
        public
        view
        returns (address oracleAddress)
    {
        return (dataFeedSourceAddress[_token]);
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWhitelist {
    function hasRoleUnlimited(address _account) external view returns (bool);
    function hasRoleAdmin(address _account) external view returns (bool);
    function hasRoleLazy(address _account) external view returns (bool);
    function hasRoleFull(address _account) external view returns (bool);
    function hasRoleFactory(address _account) external view returns (bool);
}

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