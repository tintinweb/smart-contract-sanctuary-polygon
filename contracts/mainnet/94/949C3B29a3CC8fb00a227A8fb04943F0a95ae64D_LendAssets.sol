// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
//import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
//import "../openzeppelin/OwnableUpgradeable.sol";
import "./ERC20Interface.sol";
import "./Exponential.sol";

interface IDeveloperLendLens {
    function currentExchangeRateStored(address pToken) external view returns (uint);
}

interface IPriceOracle {
    function getUnderlyingPrice(address _pToken) external view returns (uint);
}

interface IPERC20 {
    // 资产快照
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    // 获取底层代币地址
    function underlying() external view returns (address);
}

contract LendAssets is OwnableUpgradeSafe, Exponential {

    event NewTokenConfig(address token, string symbol, bool available);
    event NewPriceOracle(IPriceOracle oldPriceOracle, address newPriceOracle);
    event NewPEther(address oldPEther, address newPEther);

    // 初始化合约
    function initialize(address _PEther, address _developerLendLens) public initializer {
        PEther = _PEther;
        developerLendLens = IDeveloperLendLens(_developerLendLens);
        //将 msg.sender 设置为初始所有者。
        super.__Ownable_init();
    }
    // LEND封装查询接口
    IDeveloperLendLens public developerLendLens;

    // MATIC资金池
    address public PEther;

    IPriceOracle public oracle;
    // 资产数组
    address[] public lendAssetsList;

    // 资产地址配置映射
    mapping(address => LendConfig) public lendConfig;

    struct LendConfig {
        address pToken; // 资产地址
        string symbol;  // 资产符号
        bool available; // 可用 true/false
    }

    // 设置价格预言机
    function setPriceOracle(address newOracle) public onlyOwner {
        IPriceOracle oldOracle = oracle;
        oracle = IPriceOracle(newOracle);
        emit NewPriceOracle(oldOracle, newOracle);
    }

    // 修改新的matic资金池合约
    function setPEther(address newPEther) public onlyOwner {
        address oldPEther = PEther;
        PEther = newPEther;
        emit NewPEther(oldPEther, newPEther);
    }

    // 添加lend配置
    function addLendConfig(address pToken, string memory symbol) public onlyOwner {
        LendConfig storage config = lendConfig[pToken];
        require(config.pToken != pToken, "The pToken already exists");
        config.pToken = pToken;
        config.symbol = symbol;
        config.available = true;
        emit NewTokenConfig(pToken, symbol, config.available);
    }

    // 更新lend配置
    function updateLendConfig(address pToken, bool available) public onlyOwner {
        LendConfig storage config = lendConfig[pToken];
        require(config.pToken == pToken, "pToken does not exist");
        config.available = available;
        emit NewTokenConfig(pToken, config.symbol, available);
    }

    /**
     * @notice PCV资产统计
     * @dev
     * @param token PCV持仓资产地址
     * @param pcv pcv地址
     * @return amount 资产金额，debt 资产负债
     */
    function netAssets(address token, address pcv) external view returns (uint256 amount, uint256 debt){
        LendConfig storage config = lendConfig[token];
        amount = 0;
        debt = 0;
        if (config.pToken == token) {
            if (config.available == true) {
                (, uint balance, uint borrow, ) = IPERC20(config.pToken).getAccountSnapshot(pcv);

                uint tokenDecimals = uint(18);
                uint defaultDecimals = uint(0);
                if (token != PEther) {
                    address underlyingToken = IPERC20(config.pToken).underlying();
                    tokenDecimals = IEIP20(underlyingToken).decimals();
                }
                // 计算精度差值
                uint decimalsDifference = sub_(uint(18), tokenDecimals);
                if(decimalsDifference > uint(0)){
                    defaultDecimals = decimalsDifference;
                }
                uint price = oracle.getUnderlyingPrice(config.pToken);
                // 统计净资产
                if (balance > 0) {
                    // 获取PToken 最新汇率
                    uint exchange = developerLendLens.currentExchangeRateStored(config.pToken);
                    // 计算真实存款数量
                    balance = mul_(balance, exchange);
                    balance = div_(balance, 1e18);
                    // 转换为18为精度
                    balance = mul_(balance, 1*10**defaultDecimals);
                    amount = mulPrice(balance, price);
                }
                // 统计负债
                if (borrow > 0) {
                    borrow = mul_(borrow, 1*10**defaultDecimals);
                    debt = mulPrice(borrow, price);
                }
                return (amount, debt);
            }
        }

        return (0, 0);
    }

}