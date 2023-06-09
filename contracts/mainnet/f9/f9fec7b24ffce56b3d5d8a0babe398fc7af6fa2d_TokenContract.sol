/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract PressContract {
    mapping(address => bool) whitelistedAddresses;

    constructor() {
        TokenContract NewToken1 = new TokenContract(msg.sender,msg.sender,address(this),msg.sender,10000000);
        TokenContract NewToken2 = new TokenContract(msg.sender,msg.sender,address(this),msg.sender,100000000);
        TokenContract NewToken3 = new TokenContract(msg.sender,msg.sender,address(this),msg.sender,1000000000);
        TokenContract NewToken4 = new TokenContract(msg.sender,msg.sender,address(this),msg.sender,10000000000);
        TokenContract NewToken5 = new TokenContract(msg.sender,msg.sender,address(this),msg.sender,100000000000);
        whitelistedAddresses[address(NewToken1)] = true;
        whitelistedAddresses[address(NewToken2)] = true;
        whitelistedAddresses[address(NewToken3)] = true;
        whitelistedAddresses[address(NewToken4)] = true;
        whitelistedAddresses[address(NewToken5)] = true;
    }

    function mint(address owner_, address feesaddress_, uint256 amount_) external returns (address) {
        require(whitelistedAddresses[msg.sender], "Not in Whitelist");
        TokenContract NewToken = new TokenContract(owner_,msg.sender,address(this),feesaddress_,amount_);
        whitelistedAddresses[address(NewToken)] = true;
        return address(NewToken);
    }

    function isinwhitelist(address tokenaddress_) external view returns (bool){
        return whitelistedAddresses[tokenaddress_];
    }
}

abstract contract AbstractPressContract {
   function mint(address owner_, address feesaddress_, uint256 amount_) external virtual returns (address);
}

abstract contract StargateFinanceRouter {
       function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external virtual;
       function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external virtual returns (uint256);
}

abstract contract BeefyVaultV6 {
   function depositAll() external virtual;
   function withdrawAll() external virtual;
   function balanceOf(address account) external virtual view returns (uint256);
   function getPricePerFullShare() public virtual view returns (uint256);
}

contract TokenContract {
    IERC20 private TokenUSDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 private TokenStargateFinanceLP = IERC20(0x29e38769f23701A2e4A8Ef0492e19dA4604Be62c);
    IERC20 private TokenBeefyVaultV6 = IERC20(0x1C480521100c962F7da106839a5A504B5A7457a1);
    address private StargateFinanceRouterAddress = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address private BeefyVaultV6Address = 0x1C480521100c962F7da106839a5A504B5A7457a1;
    address private _owner;
    address private _levelupaddress;
    address private _presscontractaddress;
    address private _feesaddress;
    address private _lastminted;
    address private _lastminter;
    uint256 private _amount;
    address[] private _leveldownaddresses;

    constructor(address owner_, address levelupaddress_, address presscontractaddress_, address feesaddress_, uint256 amount_) {
        _owner = owner_;
        _levelupaddress = levelupaddress_;
        _presscontractaddress = presscontractaddress_;
        _feesaddress = feesaddress_;
        _amount = amount_;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function levelupaddress() external view returns (address) {
        return _levelupaddress;
    }

    function presscontractaddress() external view returns (address) {
        return _presscontractaddress;
    }

    function feesaddress() external view returns (address) {
        return _feesaddress;
    }
    
    function lastminted() external view returns (address) {
        return _lastminted;
    }

    function lastminter() external view returns (address) {
        return _lastminter;
    }

    function amount() external view returns (uint256) {
        return _amount;
    }

    function leveldownaddresses()external view returns( address  [] memory){
        return _leveldownaddresses;
    }

    function _SafeTransferFrom (IERC20 token, address sender, address recipient, uint256 amount_) private {
        bool sent = token.transferFrom(sender, recipient, amount_);
        require(sent,"Token transfer failed");
    }

    function balance() external view returns (uint256) {
          return (BeefyVaultV6(BeefyVaultV6Address).balanceOf(address(this)) * BeefyVaultV6(BeefyVaultV6Address).getPricePerFullShare() / 2);
    }  

    function mint() external {
        require(TokenUSDT.balanceOf(msg.sender) >= _amount, "Sender USDT wallet too low");
        
        require(TokenUSDT.allowance(msg.sender, address(this)) >= _amount, "Sender USDT allowance too low");
        
        _SafeTransferFrom(TokenUSDT, msg.sender, address(this), _amount);

        TokenUSDT.approve(address(this),TokenUSDT.balanceOf(address(this)));

        _SafeTransferFrom(TokenUSDT,address(this),_feesaddress,TokenUSDT.balanceOf(address(this)) / 500);

        TokenUSDT.approve(StargateFinanceRouterAddress, TokenUSDT.balanceOf(address(this)));
        
        StargateFinanceRouter(StargateFinanceRouterAddress).addLiquidity(2,TokenUSDT.balanceOf(address(this)), address(this));

        TokenStargateFinanceLP.approve(BeefyVaultV6Address,TokenStargateFinanceLP.balanceOf(address(this)));
        
        BeefyVaultV6(BeefyVaultV6Address).depositAll();

        _lastminted = AbstractPressContract(_presscontractaddress).mint(msg.sender, _feesaddress, _amount);

        _lastminter = msg.sender;

        _leveldownaddresses.push(_lastminted);
    }

    function claim() external {
        require(msg.sender == _owner, "Not Owner");

        TokenBeefyVaultV6.approve(address(this),TokenBeefyVaultV6.balanceOf(address(this)));

        _SafeTransferFrom(TokenBeefyVaultV6, address(this), _levelupaddress,TokenBeefyVaultV6.balanceOf(address(this)) / 2);

        BeefyVaultV6(BeefyVaultV6Address).withdrawAll();

        StargateFinanceRouter(StargateFinanceRouterAddress).instantRedeemLocal(2,TokenStargateFinanceLP.balanceOf(address(this)),address(this));

        TokenUSDT.approve(address(this),TokenUSDT.balanceOf(address(this)));

        _SafeTransferFrom(TokenUSDT, address(this), _owner,TokenUSDT.balanceOf(address(this)));
    }

    function emergencyexit() external {
        require(msg.sender == _owner, "Not Owner");

        TokenBeefyVaultV6.approve(address(this),TokenBeefyVaultV6.balanceOf(address(this)));

        _SafeTransferFrom(TokenBeefyVaultV6, address(this), _levelupaddress,TokenBeefyVaultV6.balanceOf(address(this)) / 2);

        _SafeTransferFrom(TokenBeefyVaultV6, address(this), _owner,TokenBeefyVaultV6.balanceOf(address(this)));
    }

    function transfer(address owner_) external {
        require(msg.sender == _owner, "Not Owner");

        _owner = owner_;
    }
}