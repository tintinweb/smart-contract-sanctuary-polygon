/**
 *Submitted for verification at polygonscan.com on 2023-01-23
*/

// hevm: flattened sources of src/vault/Vault.sol

pragma solidity >=0.7.0 <0.8.0;

////// src/vault/Vault.sol
/* pragma solidity ^0.7.0; */

interface ERC20Like_5 {
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function mint(address, uint) external;
    function burn(address, uint) external;
    function totalSupply() external view returns (uint);
    function approve(address usr, uint amount) external;
}

interface TrancheLike_5{
    function supplyOrder(address usr, address funder, uint newSupplyAmount) external;
    function redeemOrder(address usr, address funder, uint newRedeemAmount) external;
    function disburse(address usr) external;
    function token() external view returns (ERC20Like_5);
}

interface AdapterLike {
    function getTradeData(
        address fromToken, address toToken, uint256 amount, uint256 minReceive, bytes calldata data
    ) external view returns(address exchange, uint256 value, bytes memory transaction);

    function getSpender() external view returns (address);
}

contract Vault {
    ERC20Like_5 public currency;
    ERC20Like_5 public baseCurrency;
    ERC20Like_5 public juniorToken;
    ERC20Like_5 public seniorToken;
    TrancheLike_5 public juniorTranche;
    TrancheLike_5 public seniorTranche;
    AdapterLike public tradeAdapter;
    address public admin;
    uint8 private _initialized;


    // error CALL_FAILED();
    // error NOT_AUTHORIZED();
    // error ALREADY_INITALIZED();


    modifier Initializer {
        require(_initialized == 0, "ALREADY_INITALIZED");
        _initialized = 1;
        _;   
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "NOT_AUTHORIZED");
        _;
    }

    function initalize(
        ERC20Like_5 _vaultCurrency, 
        ERC20Like_5 _baseCurrency, 
        TrancheLike_5 _junior, 
        TrancheLike_5 _senior,
        AdapterLike _tradeAdapter,
        address _admin
    ) external Initializer {
        juniorToken = _junior.token();
        seniorToken = _senior.token();

        juniorTranche = _junior;
        seniorTranche = _senior;
        currency = _vaultCurrency;
        baseCurrency = _baseCurrency;
        tradeAdapter = _tradeAdapter;
        admin = _admin;

        baseCurrency.approve(address(_junior), type(uint256).max);
        baseCurrency.approve(address(_senior), type(uint256).max);
        baseCurrency.approve(tradeAdapter.getSpender(), type(uint256).max);
        currency.approve(tradeAdapter.getSpender(), type(uint256).max);


        juniorToken.approve(address(_junior), type(uint256).max);
        seniorToken.approve(address(_junior), type(uint256).max);
    }

    function supplyAdmin(
        address[] memory users, 
        uint256[] memory amounts, 
        uint256[] memory minCurrencyOuts,
        bool[] memory isSenior
    ) external onlyAdmin {
        for(uint256 i=0; i<users.length; i++) {
            if(isSenior[i]) {
                _supplySenior(users[i], amounts[i], minCurrencyOuts[i]);
            } else {
                _supplyJunior(users[i], amounts[i], minCurrencyOuts[i]);
            }
        }
    }

    function supplyJunior(uint256 amount, uint256 minCurrencyOut) external {
        _supplyJunior(msg.sender, amount, minCurrencyOut);
    }

    function supplySenior(uint256 amount, uint256 minCurrencyOut) external {
        _supplySenior(msg.sender, amount, minCurrencyOut);
    }

    function redeemSenior(uint256 amount) external {
        seniorToken.transferFrom(msg.sender, address(this), amount);
        seniorTranche.redeemOrder(msg.sender, address(this), amount);
        _returnToken(seniorToken, msg.sender);
    }

    function redeemJunior(uint256 amount) external {
        seniorToken.transferFrom(msg.sender, address(this), amount);
        seniorTranche.redeemOrder(msg.sender, address(this), amount);
        _returnToken(juniorToken, msg.sender);
    }

    function disburse() external {
        seniorDisburse();
        juniorDisburse();
    }

    function seniorDisburse() public {
        seniorTranche.disburse(msg.sender);

        //Convert USDC to MAI and transfer
        _returnCurrency(msg.sender);

        //transfer tranche tokens
        _returnToken(seniorToken, msg.sender);
    }

    function juniorDisburse() public {
        juniorTranche.disburse(msg.sender);

        //Convert USDC to MAI and transfer
        _returnCurrency(msg.sender);

        //transfer tranche tokens
        _returnToken(juniorToken, msg.sender);

    }

    function _supplySenior(address _user, uint256 amount, uint256 minCurrencyOut) internal {
        currency.transferFrom(_user, address(this), amount);
        
        (
            address exchange,
            ,
            bytes memory tradeData
        ) = tradeAdapter.getTradeData(
            address(currency), address(baseCurrency), amount, minCurrencyOut, ""
        );

        _call(exchange, tradeData, 0);

        seniorTranche.supplyOrder(_user, address(this), amount);
        _returnCurrency(_user);
    }

    function _supplyJunior(address _user, uint256 amount, uint256 minCurrencyOut) internal {
        currency.transferFrom(_user, address(this), amount); //TODO use safeTransfer
        (
            address exchange,
            ,
            bytes memory tradeData
        ) = tradeAdapter.getTradeData(
            address(currency), address(baseCurrency), amount, minCurrencyOut, ""
        );

        _call(exchange, tradeData, 0);

        juniorTranche.supplyOrder(_user, address(this), amount);

        _returnCurrency(_user);
    }

    ///@dev swaps the excecss USDC(if-any) to MAI and transfers it back to msg.sender
    function _returnCurrency(address _receiver) internal {
        uint256 baseCurrencyBalance = baseCurrency.balanceOf(address(this));
        if(baseCurrencyBalance > 0) {
            (
                address exchange,
                ,
                bytes memory tradeData
            ) = tradeAdapter.getTradeData(
                address(baseCurrency), address(currency), baseCurrencyBalance, 0, ""
            );

            _call(exchange, tradeData, 0);

            currency.transfer(_receiver, currency.balanceOf(address(this)));
        }
    }

    function setAdapter(AdapterLike _adapter) external onlyAdmin {
        tradeAdapter = _adapter;

        baseCurrency.approve(tradeAdapter.getSpender(), type(uint256).max);
        currency.approve(tradeAdapter.getSpender(), type(uint256).max);
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    ///@dev used to return the excess Tranche-tokens.
    function _returnToken(ERC20Like_5 token, address receiver) internal {
        uint256 balance = token.balanceOf(address(this));
        if(balance > 0) {
            token.transfer(receiver, balance);
        }
    }

    function _call(address _target, bytes memory _data, uint256 _value) internal {
        (bool result, ) = _target.call{value: _value}(_data);
        require(result, "CALL_FAILED");
    }
}