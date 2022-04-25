// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./Ownable.sol";
//import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
//import "../openzeppelin/OwnableUpgradeable.sol";
import "./ERC20Interface.sol";
import "./Exponential.sol";
//import "../libs/ErrorReporter.sol"; TokenErrorReporter

interface IPriceOracle {

    function getUnderlyingPrice(address _pToken) external view returns (uint);
}

/*interface IPERC20 {
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
}*/

interface IPcv {
    // 获取PCV指定认购代币地址
    function getSettleAsset() external view returns(address);
    // 总份额
    function totalSupply() external view returns (uint256);
}

interface IPcvStorage {
    // PCV持仓资产
    function getPcvAssets(address pcv) external view returns(address [] memory);
}

interface Assets {
    function netAssets(address token, address pcv) external view returns (uint256 amount, uint256 debt);
}

// 资产结算
contract PcvExchangeRate is OwnableUpgradeSafe, Exponential{

    event NewPriceOracle(IPriceOracle oldPriceOracle, address newPriceOracle);

    event NewPcvStorage(IPcvStorage old, address newPcvStorage);

    event NewAssetsProtocolList(address token, string belong);

    event NewTokenConfig(address token, string symbol, string source, uint collateralRate, bool available);

    // 任何抵押品质押率不得超过此值
    uint internal constant collateralFactorMaxMantissa = 0.9e18;

    // 数学精度
    uint internal constant scale = 1e18;

    IPriceOracle public oracle;

    // PCV存储合约
    IPcvStorage public pcvStorage;

    //address[] public tokenAssetsList;

    // TOKEN配置列表
    mapping(address => TokenConfig) public tokenConfig;

    // 子结算合约数组列表
    Protocol[] public assetsProtocolList;

    // 初始凭证净值
    uint256 public exchangeRateMantissa;

    // 合约初始化
    function initialize(uint _exchangeRateMantissa) public initializer {
        require(_exchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");
        exchangeRateMantissa = _exchangeRateMantissa;

        //将 msg.sender 设置为初始所有者。
        super.__Ownable_init();
    }

    // 设置价格预言机
    function setPriceOracle(address newOracle) external onlyOwner {
        IPriceOracle oldOracle = oracle;
        oracle = IPriceOracle(newOracle);
        emit NewPriceOracle(oldOracle, newOracle);
    }

    // 设置pcv存储合约
    function setPcvStorage(address newPcvStorage) external onlyOwner {
        IPcvStorage old = pcvStorage;
        pcvStorage = IPcvStorage(newPcvStorage);
        emit NewPcvStorage(old, newPcvStorage);
    }

    // 协议平台
    struct Protocol {
        address token;
        string belong;
    }
    // 设置协议平台来源
    function setAssetsProtocolList(address token, string memory belong) public onlyOwner {
        for (uint i = 0; i < assetsProtocolList.length; i++) {
            Protocol memory asset = assetsProtocolList[i];
            require(asset.token != token, "The token already exists");
        }
        assetsProtocolList.push(Protocol({
        token : token,
        belong : belong
        }));
        emit NewAssetsProtocolList(token, belong);
    }

    // 移除资产协议平台
    function removeAssetsProtocolList(address token) public onlyOwner {
        uint len = assetsProtocolList.length;
        uint assetIndex = len;
        for (uint i = 0; i < assetsProtocolList.length; i++) {
            Protocol memory asset = assetsProtocolList[i];
            if (asset.token == token) {
                assetIndex = i;
                break;
            }
        }
        assetsProtocolList[assetIndex] = assetsProtocolList[len - 1];
        assetsProtocolList.pop();
    }

    // TOKEN配置结构体
    struct TokenConfig {
        address token;  // 资产地址
        string symbol;  // 代币符号
        string source;  // 来源于哪里
        //uint baseUnit;  // 基本单位
        uint collateralRate; // 质押率
        bool available; // 是否可用
    }

    struct AssetField {
        uint256 totalAmount;   // 总资产
        uint256 netAssets;     // 净资产
        uint256 totalDebt;     // 总负债
        //uint debt;          // 负债
        uint256 netWorth;      // 净值
        uint256 availableAmount; // 可用金额
        uint256 fundsUtilization; // 资金利用率
        uint256 singleAmount;    // 单笔金额
        uint256 singleDebt;      // 单笔负债
    }

    /**
     * @notice 设置代币白名单资产列表
     * @dev token存在将添加失败
     * @param token token资产白名单地址
     * @param symbol 白名单资产符号
     * @param source 白名单资产平台来源
     * @param collateralRate 质押率
     */
    function addTokenAssetsList(address token, string memory symbol, string memory source, uint collateralRate) public onlyOwner {
        require(collateralRate <= collateralFactorMaxMantissa && collateralRate > 0, "The pledge rate exceeds the specified value");
        TokenConfig storage config = tokenConfig[token];
        require(config.token != token, "The token already exists");
        config.token = token;
        config.symbol = symbol;
        config.source = source;
        // TODO 基本单位字段暂时去掉，用于精简配置参数，后期业务需要可以加上
        // 基本单位用于决定数值输出精度，长度
        //config.baseUnit = baseUnit;
        config.collateralRate = collateralRate;
        config.available = true;

        //tokenAssetsList.push(token);
        emit NewTokenConfig(token, symbol, source, collateralRate, config.available);
    }

    /**
     * @notice 更新资产token配置
     * @dev token不存在将修改失败
     * @param token token资产白名单地址
     * @param source 白名单资产平台来源
     * @param collateralRate 质押率
     * @param available 可用
     */
    function updataTokenConfig(address token, string memory source, uint collateralRate, bool available) public onlyOwner {
        require(collateralRate <= collateralFactorMaxMantissa && collateralRate > 0, "The pledge rate exceeds the specified value");
        TokenConfig storage config = tokenConfig[token];
        require(config.token == token, "token does not exist");
        config.token = token;
        config.source = source;
        config.collateralRate = collateralRate;
        config.available = available;
        emit NewTokenConfig(token, config.symbol, source, collateralRate, available);
    }

    /**
     * @notice 获取PCV份额净值
     * @dev
     * @param pcv pcv地址
     * return (netAssets, totalDebt, netWorth) 净资产，总负债，净值(指定认购代币数量)
     */
    function netAssetValue(address pcv) external view returns (uint netAssets, uint totalDebt, uint netWorth) {
        (, netAssets, totalDebt, netWorth) = exchangeRateStoredInternal(pcv);
    }

    /**
     * @notice PCV净值统计
     * @dev
     * @param pcv pcv地址
     * @return (uint, uint, uint, uint) 总资产，净资产，总负债，净值(指定认购代币数量)
     */
    function exchangeRateStoredInternal(address pcv) internal view returns (uint, uint, uint, uint) {
        uint256 totalSupply = IPcv(pcv).totalSupply();
        if (totalSupply == 0) {
            // 如果没有铸造代币：exchangeRateMantissa
            return (0, 0, 0, exchangeRateMantissa);
        } else {
            AssetField memory vars;
            vars.totalAmount = 0;
            vars.totalDebt = 0;
            // 获取PCV持仓资产数组
            address[] memory assetsList = pcvStorage.getPcvAssets(pcv);
            for (uint i = 0; i < assetsList.length; i++) {
                // 资产数组匹配白名单资产
                TokenConfig memory config = tokenConfig[assetsList[i]];
                if (config.available == true) {
                    for (uint j = 0; j < assetsProtocolList.length; j++) {
                        Protocol memory asset = assetsProtocolList[j];
                        // 匹配子结算合约
                        if (compareStrings(config.source, asset.belong)) {
                            // 获取单笔持仓资产总金额，总负债，并累加处理数据
                            (vars.singleAmount, vars.singleDebt) = Assets(asset.token).netAssets(config.token, pcv);
                            if (vars.singleAmount > 0) {
                                vars.totalAmount = add_(vars.totalAmount, vars.singleAmount);
                            }
                            if (vars.singleDebt > 0) {
                                vars.totalDebt = add_(vars.totalDebt, vars.singleDebt);
                            }
                        }
                    }
                }
            }
            // 计算净资产 ：总资产 - 总负债
            vars.netAssets = sub_(vars.totalAmount, vars.totalDebt);
            // 计算净值
            vars.netWorth = div_(mul_(vars.netAssets, scale), totalSupply);
            // 获取PCV指定认购代币地址
            address investToken = IPcv(pcv).getSettleAsset();
            uint investTokenPrice = oracle.getUnderlyingPrice(investToken);
            // 将净值转换为指定认购代币数量
            vars.netWorth = div_(mul_(vars.netWorth, scale), investTokenPrice);
            return (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth);
        }
    }


    /**
     * @notice 获取 pcv可用金额，负债
     * @dev
     * @param pcv pcv地址
     * @return (uint, uint) 总资产，总负债
     */
    function pcvAssetsAndDebt(address pcv) public view returns (uint, uint) {
        uint amount = 0;
        uint debt = 0;
        // 获取PCV持仓资产
        address[] memory assetsList = pcvStorage.getPcvAssets(pcv);
        for (uint i = 0; i < assetsList.length; i++) {
            address token = assetsList[i];
            // 持仓资产匹配结算白名单资产
            TokenConfig memory config = tokenConfig[token];
            if (config.available == true) {
                for (uint j = 0; j < assetsProtocolList.length; j++) {
                    Protocol memory asset = assetsProtocolList[j];
                    // 匹配子结算合约
                    if (compareStrings(config.source, asset.belong)) {
                        // 获取单笔总金额，总负债
                        (uint tokenAmount, uint tokenDebt) = Assets(asset.token).netAssets(token, pcv);
                        if (tokenAmount > 0) {
                            // 处理数据，计算可借贷金额
                            tokenAmount = mul_(tokenAmount, config.collateralRate);
                            tokenAmount = div_(tokenAmount, scale);
                            amount = add_(amount, tokenAmount);
                        }
                        if (tokenDebt > 0) {
                            // 总负债累加
                            debt = add_(debt, tokenDebt);
                        }
                    }

                }
            }

        }

        return (amount, debt);
    }

    /**
     * @notice 获取 pcv资产详情数据
     * @dev
     * @param pcv pcv地址
     * @return (uint, uint, uint, uint, uint, uint) 总资产，净资产，总负债，净值(认购代币数量),可借金额，资金利用率
     */
    function getTokenAssetsData(address pcv) external view returns(uint, uint, uint, uint, uint, uint) {
        AssetField memory vars;
        (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth) = exchangeRateStoredInternal(pcv);
        (vars.availableAmount, ) = pcvAssetsAndDebt(pcv);
        vars.fundsUtilization = div_(mul_(vars.totalDebt, scale), vars.availableAmount);
        return (vars.totalAmount, vars.netAssets, vars.totalDebt, vars.netWorth, vars.availableAmount, vars.fundsUtilization);
    }

    /**
     * @notice 获取 pcv单资产最大可借，可取
     * @dev
     * @param pcv pcv地址
     * @param token 单资产地址
     * return (maxBorrowAmount, maxBorrow, maxRedeemAmount, maxRedeem) 最大可借金额，最大可借数量，最大可取金额，最大可取数量
     */
    function pcvMaxBorrowAndRedeem(address pcv, address token) external view returns(uint maxBorrowAmount, uint maxBorrow, uint maxRedeemAmount, uint maxRedeem){
        AssetField memory vars;
        TokenConfig memory config = tokenConfig[token];
        // 计算可借，可取金额
        (vars.availableAmount, vars.totalDebt) = pcvAssetsAndDebt(pcv);
        uint amount = sub_(vars.availableAmount, vars.totalDebt);
        maxBorrowAmount = div_(amount, sub_(scale, config.collateralRate));
        (maxRedeemAmount, , , ) = exchangeRateStoredInternal(pcv);
        // 计算可借，可取数量
        uint price = oracle.getUnderlyingPrice(token);
        maxBorrow = div_(mul_(maxBorrowAmount, scale), price);
        maxRedeem = div_(mul_(maxRedeemAmount, scale), price);
        return (maxBorrowAmount, maxBorrow, maxRedeemAmount, maxRedeem);
    }

    // 字符串判断
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}