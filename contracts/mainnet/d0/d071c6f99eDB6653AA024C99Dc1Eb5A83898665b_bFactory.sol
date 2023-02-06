// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./bWalletPolygon.sol";

contract bFactory {
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

    constructor() payable {}

    function deployWallet() public returns (address) {
        uint256 _salt = convertAddr(msg.sender);

        address newAddress = address(
            new bWalletPolygon{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress, msg.sender, _salt);

        return newAddress;
    }

    function deployWithAddress(address _addr, uint256 _salt)
        public
        returns (address)
    {
        address newAddress = address(
            new bWalletPolygon{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWalletFromAddress(newAddress, msg.sender, _addr, _salt);
        return newAddress;
    }

    function deployWithAddressAndValue(address _addr, uint256 _salt)
        public
        payable
        returns (address)
    {
        address newAddress = address(
            new bWalletPolygon{salt: bytes32(_salt), value: msg.value}(_addr)
        );
        emit newWalletFromAddressAndValue(
            newAddress,
            msg.sender,
            _addr,
            _salt,
            msg.value
        );
        return newAddress;
    }

    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(bWalletPolygon).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    function getAddress(uint256 _salt) public view returns (address) {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function convertAddr(address _addr) public pure returns (uint256) {
        uint256 _salt = uint256(uint160(_addr));

        return _salt;
    }

    function send(address payable _to, uint256 _amount) public payable {
        _to.transfer(_amount);
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
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;

    // map  ERC20 tokens to user
    mapping(address => uint256) public tokenStaked;

    address public bitsManager = 0x07f899CA879Ba85376D710fE448B88aF53049067;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public aaveLendingPool = 0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;
    address public quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public meshSwapRouter = 0x10f4A785F458Bc144e3706575924889954946639;
    address public aEthWETH = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;
    address public iWMatic = 0xb880e6AdE8709969B9FD2501820e052581aC29Cf;
    address iMESH = 0x6dBADf2a3e53885076f1D30B6198e560830cb4Bb; // pool
    address MESH = 0x82362Ec182Db3Cf7829014Bc61E9BE8a2E82868a; // token
    address USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // token
    address iUSDC = 0x590Cd248e16466F747e74D4cfa6C48f597059704; // pool
    address iUSDT = 0x782D7eC740d997445D62e4463ce64C67c7484497; // pool
    address USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // token

    address public WrappedTokenGatewayV3 =
        0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
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

        aEthWETHcontract = IERC20(aEthWETH);
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
        IERC20(_token).transfer(msg.sender, fee);
        IERC20(_token).transfer(address(bitsManager), finalAmount);
        emit SplitFee(msg.sender, _token, finalAmount, feeValue);
        totalFee += feeValue;
    }

    // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- [ [ MESHSWAP ]]  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

    function stakeMATIC() public payable onlyOwner {
        require(msg.value > 0, "You must send some ETH");

        // encode function call with depositETH

        bytes memory data = abi.encodeWithSignature("depositETH()");

        (bool success, ) = iWMatic.call{value: msg.value}(data);

        require(success, "Error depositing ETH");
        staked[WMATIC] += msg.value;
        emit StakedMaticMesh(msg.sender, msg.value);
    }

    function unStakeMATIC() public onlyOwner {
        bytes memory data = abi.encodeWithSignature(
            "withdrawETHByAmount(uint256)",
            maxUint
        );
        staked[WMATIC] = 0;
        (bool success, ) = iWMatic.call(data);

        require(success, "Error withdrawing Matic");

        emit UnStakedMeshMatic(msg.sender, WMATIC, maxUint);
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

    function stakeMeshTokenAmount(
        address _token,
        address _iToken,
        uint256 _amount
    ) public onlyOwner {
        meshContract = MeshGateway(_iToken);

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
        // approve weth

        approveWeth(WrappedTokenGatewayV3, maxUint);

        aaveContract.depositETH{value: msg.value}(
            aaveLendingPool,
            address(this),
            0
        );
        values[msg.sender] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit StakedAave(msg.sender, msg.value);
    }

    ///////////////////////////////////////// unstake matic on aave /////////////////////////////////

    function unstakeETHAave() public {
        aaveContract.withdrawETH(aaveLendingPool, maxUint, address(this));
    }

    function approveWMATIC(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    function approveWeth(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
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