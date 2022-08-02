/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

pragma abicoder v2;
pragma solidity ^0.7.6;

interface IERC20String {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

interface IERC20Bytes32 {
    function symbol() external view returns (bytes32);

    function name() external view returns (bytes32);
}

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

interface IERC20Balance {
    function balanceOf(address) external view returns (uint);
}


// 0x88757f2f99175387ab4c6a4b3067c77a695b0349 - kovan lending pool
interface ILendingPoolAddressesProvider {
  function getAddress(bytes32 id) external view returns (address);
}

  struct TokenData {
    string symbol;
    address tokenAddress;
  }

interface IAaveProtocolDataProvider {
  function getAllATokens() external view returns (TokenData[] memory);
}


contract QueryAaveTokens {
    struct ATokenInfo {
        string symbol;
        string name;
        uint8 decimals;
        address contract_address;
        uint256 balance;
    }
    // function getInfoBatch(address lending_pool, address user, string[] memory tokens)
    // external
    // view
    // returns (ATokenInfo[] memory infos)
    // {

    //     ATokenInfo[] memory infos = new ATokenInfo[](tokens.length);
    //     for (uint8 i = 0; i < tokens.length; i++) {
    //         Info memory info;
    //         infos[i] = this.getInfo(user, tokens[i]);
    //     }
    //     return infos;
    // }


    function getDataProviderAddress(address lending_pool) external view returns(address data_provider_address) {
        uint8 number = 1;
        bytes32 id = bytes32(bytes1(number));
        data_provider_address = ILendingPoolAddressesProvider(lending_pool).getAddress(id);
    }

    // 0x3c73A5E5785cAC854D468F727c606C07488a29D6 kovan
    function getAllATokens(address dataProvider) external view returns (TokenData[] memory x) {
        x = IAaveProtocolDataProvider(dataProvider).getAllATokens();
    }


    function getUserATokenBalances(address lending_pool, address wallet_address) external view returns (ATokenInfo[] memory infos) {
        address data_provider_address = this.getDataProviderAddress(lending_pool);
        TokenData[] memory aTokenData = this.getAllATokens(data_provider_address);
        address[] memory token_adresses = new address[](aTokenData.length);
         for (uint i = 0; i < aTokenData.length; i++) {
            token_adresses[i] = aTokenData[i].tokenAddress;
        }
        return this.getInfoBatch(wallet_address, token_adresses);
    }

    function getInfoBatch(address user, address[] memory tokens)
    external
    view
    returns (ATokenInfo[] memory infos)
    {
        infos = new ATokenInfo[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            infos[i] = this.getInfo(user, tokens[i]);
        }
        return infos;
    }

    function getInfo(address user, address token) external view returns (ATokenInfo memory info) {
        // Does code exists for the token?
        uint32 size;

        assembly {
            size := extcodesize(token)
        }
        info.contract_address = token;

        if (size == 0) {
            return info;
        }

        info.decimals = this.getDecimals(token);
        info.balance = this.getBalance(user, token);

        try this.getStringProperties(token) returns (
            string memory _symbol,
            string memory _name
        ) {
            info.symbol = _symbol;
            info.name = _name;
            return info;
        } catch {}
        try this.getBytes32Properties(token) returns (
            string memory _symbol,
            string memory _name
        ) {
            info.symbol = _symbol;
            info.name = _name;
            return info;
        } catch {}
    }

    function getBalance(address user, address token)
    external
    view
    returns (uint256 balance)
    {
        balance = IERC20Balance(token).balanceOf(user);
    }

    function getDecimals(address token)
    external
    view
    returns (uint8 decimals)
    {
        decimals = IERC20Decimals(token).decimals();
    }

    function getStringProperties(address token)
    external
    view
    returns (string memory symbol, string memory name)
    {
        symbol = IERC20String(token).symbol();
        name = IERC20String(token).name();
    }

    function getBytes32Properties(address token)
    external
    view
    returns (string memory symbol, string memory name)
    {
        bytes32 symbolBytes32 = IERC20Bytes32(token).symbol();
        bytes32 nameBytes32 = IERC20Bytes32(token).name();
        symbol = bytes32ToString(symbolBytes32);
        name = bytes32ToString(nameBytes32);
    }

    function bytes32ToString(bytes32 _bytes32)
    internal
    pure
    returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}