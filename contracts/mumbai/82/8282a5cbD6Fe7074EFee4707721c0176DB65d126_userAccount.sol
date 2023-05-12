//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./whitelistedTokens.sol";

interface ERC20Interface {
    function allowance(address, address) external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function approve(address, uint) external;

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint) external returns (bool);
}

interface UniswapInterface {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface UniswapV3Interface {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// kind: The type of swap to perform - either "Out Given Exact In" or "In Given Exact Out."
// GIVEN_IN: The amount of tokens being sent
// GIVEN_OUT: The amount of tokens being received

interface BalancerV2Interface {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
    struct SingleSwap {
        bytes32 poolId;
        // SwapKind kind;
        uint8 kind;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

contract userAccount is Initializable {
    address public userOwner;
    uint256 public ORDER_ID = 1;
    address public whitelistedAddress;
    mapping(uint256 => mapping(address => int256)) public depositAmt;
    mapping(uint256 => bool) public isCanceled;
    mapping(uint256 => address) public orderIdTokenAddress;
    mapping(uint256 => bool) public isOrderExecuted;
    function initialize(
        address _userOwner,
        address _whitelistedAddress
    ) external initializer {
        userOwner = _userOwner;
        whitelistedAddress = _whitelistedAddress;
    }

    modifier onlyOwner() {
        require(
            msg.sender == userOwner,
            "Only the contract user owner can perform this action."
        );
        _;
    }
    function addOrder(address erc20, int256 amt) external onlyOwner {
        require(amt > 0, "Deposit amount must be greater than zero.");
        bool isTrue = whitelistedTokens(whitelistedAddress).isWhitelisted(
            erc20
        );
        require(isTrue, "not a whitelisted contract");
        ERC20Interface(erc20).transferFrom(
            msg.sender,
            address(this),
            uint256(amt)
        );
        depositAmt[ORDER_ID][erc20] = amt;
        orderIdTokenAddress[ORDER_ID] = erc20;
        ORDER_ID++;
    }

    function cancelOrder(uint256 orderId) external onlyOwner {
        require(isCanceled[orderId] == false, "orderId is already canceled");
        address erc20 = orderIdTokenAddress[orderId];
        isCanceled[orderId] = true;
        int256 amt = depositAmt[orderId][erc20];
        depositAmt[orderId][erc20] = 0;
        ERC20Interface(erc20).transfer(msg.sender, uint256(amt));
    }
    function executeOrderSimilarDexUniswapV2(
        uint256 orderId,
        address addressOfexchange,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        require(!isCanceled[orderId], "order is cancelled");
        address erc20 = orderIdTokenAddress[orderId];
        int256 amt = depositAmt[orderId][erc20];
        uint amountIn = uint(amt);
        UniswapInterface uniswapInterface = UniswapInterface(addressOfexchange);
        uint[] memory amount = uniswapInterface.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        ERC20Interface(path[1]).transfer(userOwner, amount[1]);

    }

    function executeOrderUniswapV3(
        uint256 orderId,
        address addressOfexchange,
        UniswapV3Interface.ExactInputSingleParams memory params
    ) external {
        require(!isCanceled[orderId], "order is cancelled");
        address erc20 = orderIdTokenAddress[orderId];
        int256 amt = depositAmt[orderId][erc20];
        params.amountIn = uint(amt);
        UniswapV3Interface uniswapV3Interface = UniswapV3Interface(
            addressOfexchange
        );
        uint amount = uniswapV3Interface.exactInputSingle(params);
        ERC20Interface(params.tokenOut).transfer(userOwner, amount);  
    }

    function executeOrderBalancerV2(
        uint256 orderId,
        address addressOfexchange,
        BalancerV2Interface.SingleSwap memory singleSwap,
        BalancerV2Interface.FundManagement memory funds,
        uint limit,
        uint deadline
    ) external {
        require(!isCanceled[orderId], "order is cancelled");
        address erc20 = orderIdTokenAddress[orderId];
        int256 amt = depositAmt[orderId][erc20];
        singleSwap.amount= uint(amt);
        singleSwap.userData = "0x";
        BalancerV2Interface balancerV2Interface = BalancerV2Interface(
            addressOfexchange
        );
        uint256 amount = balancerV2Interface.swap(
            singleSwap,
            funds,
            limit,
            deadline
        );
        ERC20Interface(singleSwap.tokenOut).transfer(userOwner, amount);
    }

    function approve(address spender, uint256 orderId) external {
        address erc20 = orderIdTokenAddress[orderId];
        int256 amt = depositAmt[orderId][erc20];
        uint amount = uint(amt);
        ERC20Interface erc20Interface = ERC20Interface(erc20);
        erc20Interface.approve(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract whitelistedTokens {
    mapping(address => bool) public isWhitelisted;
     address immutable public adminAddress;
     constructor() {
         adminAddress = msg.sender;
    }
    modifier onlyAdmin() {
    require(msg.sender == adminAddress, "Only the contract owner can perform this action.");
    _;
    }   
    function whitelistAddress(address adr) external onlyAdmin{
        isWhitelisted[adr] =true;
    }
    function iswhitelist(address adr) public view returns(bool){
        return isWhitelisted[adr];
    }
}