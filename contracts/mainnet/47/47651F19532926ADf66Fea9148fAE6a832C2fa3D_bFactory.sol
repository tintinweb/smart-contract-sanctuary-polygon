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





pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./bWalletPolygon.sol";

contract bFactory is Ownable {
    event newWallet(address wallet, address owner, uint256 salt);
    event newWalletFromAddress(
        address wallet,
        address deployer,
        address owner,
        uint256 salt
    );
    event newWalletFromAddressAndValue(
        address wallet,
        address deployer,
        address owner,
        uint256 salt,
        uint256 value
    );
    event addressConverted(uint256 salt, address owner);
  mapping(address => address payable) public wallets;



    constructor() payable {}
 


    function deployWithAddress(address _addr)
        external
        onlyOwner
        returns (address)
    {
        uint256 _salt = convertAddr(_addr);
        address newAddress = address(
            new bWalletPolygon{salt: bytes32(_salt)}(address(this))
        );

        wallets[_addr] = payable(newAddress);

        emit newWalletFromAddress(newAddress, msg.sender, _addr, _salt);
        return newAddress;
    }


    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(bWalletPolygon).creationCode;
        return abi.encodePacked(bytecode, abi.encode(address(this)));
    }


    function getWalletFromUserAddress(address user) public view returns (address) {
      uint256 _salt = convertAddr(user);
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), 
                address(this),  
             _salt,
                keccak256(getBytecode ())
            )
        );
 
        return address(uint160(uint256(hash)));
    }

    function convertAddr(address _addr) public pure returns (uint256) {
        uint256 _salt = uint256(uint160(_addr));

        return _salt;
    }

    function send(address payable _to, uint256 _amount)
        public
        payable
        onlyOwner
    {
        _to.transfer(_amount);
    }
    function withDrawMatic() public onlyOwner {
        bool success;
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");

    }

    // find wallet by address 
    function findWallet(address _addr) public view returns (address) {
        return wallets[_addr];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface MeshGateway {
    function depositETH() external payable;

    function depositToken(uint256 amount) external;

    function withdrawToken(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function withdrawETH(uint256 withdrawAmount) external;

    function withdrawETHByAmount(uint256 withdrawAmount) external;

    function withdrawTokenByAmount(uint256 withdrawTokens) external;
}

interface MeshRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract bWalletPolygon {
    address public owner;
    uint256 public nonce;
    event StakedToken(
        address sender,
        address token,
        address iToken,
        uint256 amount
    );
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    event Replayed(address, uint256, uint256 fee);
    event FeeIncoming(address, uint256 finalAmt, uint256 fee);
    event StakedMesh(address, uint256);
    event StakedAave(address, uint256);
    event UnStakedMesh(address, uint256);
    event UnStakedToken(address, address token, address iToken, uint256 amount);
    event UnStakedMeshMatic(address sender, address token, uint256 amount);
    event StakedMaticMesh(address sender, uint256 amount);
    event SplitFee(
        address sender,
        address token,
        uint256 finalAmount,
        uint256 fee
    );
    event StakedBalanceMesh(address user, address _iToken, uint256 _amount);
    event UnStakedAave(address sender, uint256 amount);
    event unStakedERC20aave(address sender, address token, uint256 amount);
    event StakedERC20aave(address sender, address token, uint256 amount);

    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;
    mapping(address => uint256) aaveMaticStaked;

    // map  ERC20 tokens to user
    mapping(address => uint256) public tokenStaked;
    mapping(address => uint256) public tokenStakedAave;

    address public bitsManager = 0x07f899CA879Ba85376D710fE448B88aF53049067;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address public quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public meshSwapRouter = 0x10f4A785F458Bc144e3706575924889954946639;
    address public aPolWMATIC = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;
    address public iWMatic = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf;
    address iMESH = 0x6dBADf2a3e53885076f1D30B6198e560830cb4Bb; // pool
    address MESH = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a; // token
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // token
    address iUSDC = 0x590Cd248e16466F747e74D4cfa6C48f597059704; // pool
    address iUSDT = 0x782D7eC740d997445D62e4463ce64C67c7484497; // pool
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // token

    address public WrappedTokenGatewayV3 =
        0x1e4b7A6b903680eab0c5dAbcb8fD429cD2a9598c;
    uint256 public bitsValue;
    uint256 public totalFee;
    uint256 public feez = 85;
    uint256 maxUint =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    IWETHGateway public aaveContract;
    MeshGateway public meshContract;
    MeshRouter public meshRouter;

    IERC20 public aEthWETHcontract;

    mapping(address => uint256) public userStakedAmount;
    mapping(address => uint256) public userStakedAmountMesh;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(bitsManager == msg.sender, "Manager only");
        _;
    }

    constructor(address _owner) payable {
        owner = _owner;

        _aaveContract = 0x1e4b7A6b903680eab0c5dAbcb8fD429cD2a9598c;
        aaveContract = IWETHGateway(_aaveContract);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function updateFee(uint256 _feez) public onlyManager {
        feez = _feez;
    }

    function send(address payable _to, uint256 _amount) external onlyManager {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        nonce += 1;
        emit Sent(_to, _amount);
    }

    ///////////////////////////////////////// split fee and send matic  ////////////////////////////////////
    function SplitIt() public onlyOwner {
        uint256 _staked = userStakedAmount[msg.sender];
        uint256 feeValue = address(this).balance - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        userStakedAmount[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: finalAmount}("");
        require(sent, "Failed to send Ether");
        (bool sent2, ) = address(bitsManager).call{value: fee}("");
        require(sent2, "Failed to send Ether");
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
    }

    ///////////////////////////////////////// split fee and send ERC20  ////////////////////////////////////
    function SplitItERC20(address _token) public onlyOwner {
        uint256 _staked = staked[_token];
        uint256 feeValue = IERC20(_token).balanceOf(address(this)) - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        staked[_token] = 0;
        IERC20(_token).transfer(msg.sender, finalAmount);
        IERC20(_token).transfer(address(bitsManager), fee);
        emit SplitFee(msg.sender, _token, finalAmount, feeValue);
        totalFee += feeValue;
    }

    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- [ [ MESHSWAP ]]  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

    function stakeMeshswapMatic() public payable onlyOwner {
        require(msg.value > 0, "You must send some ETH");

        // encode function call with depositETH

        bytes memory data = abi.encodeWithSignature("depositETH()");

        (bool success, ) = iWMatic.call{value: msg.value}(data);

        require(success, "Error depositing ETH");
        staked[WMATIC] += msg.value;
        emit StakedMaticMesh(msg.sender, msg.value);
    }

    /////////////////////////////////////////  stake tokens on meshswap  ///////////////////////////////////

    function stakeMeshToken(address _token, address _iToken) public onlyOwner {
        meshContract = MeshGateway(_iToken);

        uint256 _amount = IERC20(_token).balanceOf(address(this));

        IERC20(_token).approve(_iToken, maxUint);

        meshContract.depositToken(_amount);

        staked[_token] += _amount;
        staked[_iToken] += _amount;

        emit StakedToken(msg.sender, _token, _iToken, _amount);
    }

    ///////////////////////////////////////// unstake tokens on meshswap /////////////////////////////////
    function unStakeMeshToken(address _token, address _iToken)
        public
        onlyOwner
    {
        meshContract = MeshGateway(_iToken);
        uint256 _amount = staked[_token];
        staked[_token] = 0;
        staked[_iToken] = 0;

        meshContract.withdrawTokenByAmount(maxUint);

        emit UnStakedToken(msg.sender, _token, _iToken, _amount);
    }

    ///////////////////////////////////////// unstake tokens on meshswap /////////////////////////////////
    function unStakeMeshTokenAmount(
        address _token,
        address _iToken,
        uint256 _amount
    ) public {
        staked[_token] -= _amount;
        staked[_iToken] -= _amount;

        meshContract = MeshGateway(_iToken);
        meshContract.withdrawToken(_amount);
        userStakedAmountMesh[msg.sender] -= _amount;
        emit UnStakedToken(msg.sender, _token, _iToken, _amount);
    }

    /////////////////////////////////////////  unstake matic on meshswap /////////////////////////////////
    function withdrawMaticMesh() public {
        uint256 _amount = staked[WMATIC];
        staked[WMATIC] = 0;
        meshContract.withdrawETHByAmount(maxUint);
        emit UnStakedMeshMatic(msg.sender, WMATIC, _amount);
    }

    ///////////////////////////////////////// swap Mesh to USDC  /////////////////////////////////
    function swapMeshToUSDC() public onlyOwner {
        uint256 _amount = ERC20Balance(MESH);
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = MESH;
        path[1] = USDC;
        meshRouter.swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(msg.sender),
            block.timestamp
        );
    }

    function swapERC20MeshSwap(
        address _from,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        // approve both  tokens
        approveERC20(_from, address(meshRouter));
        approveERC20(_to, address(meshRouter));

        // swap tokens
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        meshRouter.swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(msg.sender),
            block.timestamp + 1000
        );
    }

    /////////////////////////////////////////   Approvals /////////////////////////////////

    function approveERC20(address _token, address _spender) public {
        IERC20(_token).approve(_spender, maxUint);
    }

    /////   Approve tokens for staking on meshswap ////

    function approveMeshTokensForStaking() public {
        IERC20 wmaticToken = IERC20(WMATIC);
        IERC20 usdcToken = IERC20(USDC);
        IERC20 usdtToken = IERC20(USDT);
        IERC20 meshToken = IERC20(MESH);

        wmaticToken.approve(iWMatic, maxUint);
        usdcToken.approve(iUSDC, maxUint);
        usdtToken.approve(iUSDT, maxUint);
        meshToken.approve(iMESH, maxUint);
    }

    /////   Approve tokens for swapping on meshswap /////
    function approveMeshTokensForSwapping() public {
        IERC20 wmaticToken = IERC20(WMATIC);
        IERC20 usdcToken = IERC20(USDC);
        IERC20 usdtToken = IERC20(USDT);
        IERC20 meshToken = IERC20(MESH);

        wmaticToken.approve(meshSwapRouter, maxUint);
        usdcToken.approve(meshSwapRouter, maxUint);
        usdtToken.approve(meshSwapRouter, maxUint);
        meshToken.approve(meshSwapRouter, maxUint);
    }

    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- [ [ AAVE ]]  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

    ///////////////////////////////////////// stake matic on aave /////////////////////////////////

    function stakeETHAave() public payable {
        require(msg.value > 0, "You must send some ETH");
        IERC20 WMATICcontract = IERC20(WMATIC);
        WMATICcontract.approve(WrappedTokenGatewayV3, maxUint);
        aaveContract.depositETH{value: msg.value}(aavePool, address(this), 0);
        aaveMaticStaked[msg.sender] += msg.value;
        emit StakedAave(msg.sender, msg.value);
    }

    ///////////////////////////////////////// unstake matic on aave /////////////////////////////////

    function unstakeETHAave() public {
        IERC20 aPolWMATICcontract = IERC20(aPolWMATIC);
        aPolWMATICcontract.approve(WrappedTokenGatewayV3, maxUint);
        uint256 OgStked = aaveMaticStaked[msg.sender];
        aaveMaticStaked[msg.sender] = 0;
        aaveContract.withdrawETH(aavePool, maxUint, address(this));
        emit UnStakedAave(msg.sender, OgStked);
    }

    function approveWMATIC() public returns (bool) {
        IERC20 aPolWMATICcontract = IERC20(aPolWMATIC);
        aPolWMATICcontract.approve(WrappedTokenGatewayV3, maxUint);
        IERC20 WMATICcontract = IERC20(WMATIC);
        WMATICcontract.approve(WrappedTokenGatewayV3, maxUint);
        return true;
    }

    /////// stake  erc20 to aave ////////

    function stakeERC20aave(address _token, uint256 _amount) public {
        IERC20(_token).approve(aavePool, maxUint);
        aaveContract.supply(_token, _amount, address(this), 0);
        tokenStakedAave[_token] += _amount;

        emit StakedERC20aave(msg.sender, _token, _amount);
    }

    /////// withdraw erc20 from aave ////////

    function unstakeERC20aave(address _token) public {
        uint256 OgStaked = tokenStakedAave[_token];
        tokenStakedAave[_token] = 0;
        aaveContract.withdraw(_token, OgStaked, address(this));
    }

    function unstakeERC20aaveByAMount(address _token, uint256 _amount) public {
        tokenStakedAave[_token] -= _amount;
        aaveContract.withdraw(_token, _amount, address(this));
        emit unStakedERC20aave(msg.sender, _token, _amount);
    }

    ///////////////////////////////////////// Balances /////////////////////////////////

    function ERC20Balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getMeshBalance() public view returns (uint256) {
        return ERC20Balance(MESH);
    }

    function getUSDCBalance() public view returns (uint256) {
        return ERC20Balance(USDC);
    }

    ///////////////////////////////////////// admin functions /////////////////////////////////

    function destroy(address where) public onlyOwner {
        selfdestruct(payable(where));
    }

    function updateManager(address _bitsManager) public onlyOwner {
        bitsManager = _bitsManager;
    }

    function withDrawERC20(address _token) public onlyOwner {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnership(address _newOwner) external onlyManager {
        owner = _newOwner;
    }

    function withdraw() external onlyManager {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }
}