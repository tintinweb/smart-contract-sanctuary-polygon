// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IMasterchief {
    struct ShareholderExtended {
        address controller;
        address account;
        uint256 createdAt;
        uint256 delay;
        uint256 share;
        uint256 shares;
        uint256 totalClaims;
        uint256 tokenAmountClaimed;
        uint256 tokenAmountUnclaimed;
        bytes params;
    }

    function router() external view returns (address);
    function governanceToken() external view returns (address);
    function pathBatch() external view returns(address[][] memory);
    function sellTaxPermille() external view returns(uint256);

    function unclaimed(
        address controller,
        address ref,
        uint256 blockNumber,
        uint256 delay,
        uint256 share,
        uint256 shares
    ) external view returns (uint256);
}

interface IToken {
    struct Allowance {
        address spender;
        uint256 amount;
    }

    struct Token {
        int256 pathId;
        address[] path;
        uint256 decimals;
        uint256 totalSupply;
        uint256 reserveToken0;
        uint256 reserveToken1;
        uint256 reserveNativeToken0;
        uint256 reserveNativeToken1;
        uint256 lp;
        uint256 buyPriceUSDC;
        uint256 sellPriceUSDC;
        uint256 sellTaxPermille;
        uint256 balance;
        Allowance[] allowances;
    }

    function decimals() external pure returns (uint256);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount
    ) external returns (bool);
}

interface IGovernanceToken {
    function balanceOf(address account) external view returns (uint256);
}

interface IController {
    function denominator() external view returns(uint256);

    function shareholder(
        address account,
        bytes memory params
    ) external view returns (IMasterchief.ShareholderExtended memory);
}

interface INFT {
    struct Nft {
        uint256 id;
        uint256 index;
        uint256 edition;
        uint256 total;
        uint256 balance;
        uint256 createdAt;
        uint256 updatedAt;
        int256 category;
        address controller;
        bytes params;
    }

    struct Data {
        uint256 id;
        uint256 updatedAt;
        bytes params;
		}

    struct Approved {
        address operator;
        bool approved;
    }

    struct NftExtended {
        uint256 id;
        uint256 index;
        uint256 edition;
        uint256 total;
        uint256 balance;
        uint256 createdAt;
        uint256 updatedAt;
        int256 category;
        address controller;
        bytes params;

        uint256 tokenAmountUnclaimed;

        uint256 reserveNft;
        uint256 reserveToken;

        uint256 buyPriceToken;
        uint256 sellPriceToken;

        uint256 buyPriceGovernanceToken;
        uint256 sellPriceGovernanceToken;

        uint256 royaltyPermille;

        Approved[] approved;
    }

    function idBatch(
        address account,
        address[] memory controllers,
        int256[][] memory categories
    ) external view returns (uint256[] memory);

    function nftDataBatch(
        uint256[] calldata ids
    ) external view returns (INFT.Data[] memory);

    function nft(
        uint256 id,
        address account
    ) external view returns (INFT.Nft memory);

    function nftBatch(
        uint256[] calldata ids,
        address account
    ) external view returns (INFT.Nft[] memory);

    function categoryBatch(
        address controller
    ) external view returns (int256[] memory);

    function totalCategoryIds(
        address controller,
        int256 category
    ) external view returns (uint256);

    function categoriesIdBatch(
        address controller,
        int256[] calldata categories,
        uint256[] calldata skips,
        uint256[] calldata totals
    ) external view returns (uint256[][] memory);

    function isApprovedForAllBatch(
        address account,
        address[] memory operators
    ) external view returns (Approved[] memory);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);
}

interface INifty {
    function getGlobalRoyaltyFee() external view returns (uint256);

    function getCurrencyReserves(
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

    function getPrice_tokenToCurrency(
        uint256[] calldata _ids,
        uint256[] calldata _tokensSold
    ) external view returns (uint256[] memory);

    function getPrice_currencyToToken(
        uint256[] calldata _ids,
        uint256[] calldata _tokensSold
    ) external view returns (uint256[] memory);
}

interface IFactory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IRouter {
    function factory() external view returns (address);
}

interface IPair {
    function getReserves() external view returns (uint256, uint256, uint256);
    function token0() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

import "@openzeppelin/contracts/utils/Strings.sol";

contract Utils {
    address[] public controllers;
    INFT public immutable nft;
    INifty public immutable nifty;
    IGovernanceToken public immutable governanceToken;
    IMasterchief public immutable masterchief;

    constructor(
        address[] memory controllers_,
        INFT nft_,
        INifty nifty_,
        IGovernanceToken governanceToken_,
        IMasterchief masterchief_
    )
    {
        controllers = controllers_;
        nft = nft_;
        nifty = nifty_;
        governanceToken = governanceToken_;
        masterchief = masterchief_;
    }

    receive() external payable {}
    fallback() external payable {}

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    )
        external
    {
        uint256 delta = gasleft();
        (bool success, ) = target.call{value: value}(data);
        delta -= gasleft();

        require(success, "GasEstimator: underlying transaction reverted");
        revert(string(abi.encodePacked('gasUsed: ', Strings.toString(delta))));
    }

    function shareholderBatch(
        address account,
        address[] calldata controllers_,
        bytes[] calldata params
    )
        external
        view
        returns (IMasterchief.ShareholderExtended[] memory)
    {
        IMasterchief.ShareholderExtended[] memory shareholders = new IMasterchief.ShareholderExtended[](controllers_.length);
        for (uint256 i = 0; i < controllers_.length; i++) {
          shareholders[i] = IController(controllers_[i]).shareholder(account, params[i]);
        }
        return shareholders;
    }

    function tokenBatch(
       address account,
       address[] calldata spenders
    )
       external
       view
       returns (IToken.Token[] memory)
    {
        address[][] memory paths = masterchief.pathBatch();
        IToken.Token[] memory tokens = new IToken.Token[](paths.length + 2);
        IFactory factory = IFactory(IRouter(masterchief.router()).factory());
        IToken token;
        for (uint256 i = 0; i < paths.length; i++) {
            token = IToken(paths[i][paths[i].length - 1]);
            tokens[i] = _token(factory, paths[i], paths[2][paths[2].length - 1]);

            tokens[i].pathId = int256(i);
            tokens[i].decimals = token.decimals();
            tokens[i].buyPriceUSDC = _buyPriceUSDC((i == 1) ? 10**18 : 10**tokens[i].decimals, tokens[i].reserveToken0, tokens[i].reserveToken1);
            tokens[i].sellPriceUSDC = _sellPriceUSDC((i == 1) ? 10**18 : 10**tokens[i].decimals, tokens[i].reserveToken0, tokens[i].reserveToken1);
            tokens[i].balance = (account != address(0)) ? token.balanceOf(account) : 0;
            tokens[i].allowances = _allowances(token, account, spenders);
        }

        tokens[0].totalSupply = IToken(paths[0][0]).totalSupply();

        (tokens[0].lp, tokens[1].lp) = (tokens[1].lp, tokens[0].lp);
        (tokens[0].reserveToken0, tokens[0].reserveToken1) = (tokens[1].reserveToken0, tokens[1].reserveToken1);
        (tokens[1].reserveToken0, tokens[1].reserveToken1) = (0, 0);
        (tokens[0].buyPriceUSDC, tokens[0].sellPriceUSDC) = (tokens[1].buyPriceUSDC, tokens[1].sellPriceUSDC);
        (tokens[1].buyPriceUSDC, tokens[1].sellPriceUSDC) = (1000000, 1000000);

        tokens[paths.length] = _governanceToken(factory, paths[1], account, spenders);

        tokens[paths.length + 1] = IToken.Token({
            pathId: -2,
            path: new address[](1),
            decimals: 18,
            totalSupply: 0,
            reserveToken0: 0,
            reserveToken1: 0,
            reserveNativeToken0: 0,
            reserveNativeToken1: 0,
            lp: 0,
            buyPriceUSDC: tokens[2].buyPriceUSDC,
            sellPriceUSDC: tokens[2].sellPriceUSDC,
            sellTaxPermille: 0,
            balance: (account != address(0)) ? account.balance : 0,
            allowances: new IToken.Allowance[](0)
        });

        return tokens;
    }

    function totalCategoryIdBatch(
        address controller
    )
        external
        view
        returns (int256[] memory, uint256[] memory)
    {
        int256[] memory categories = nft.categoryBatch(controller);
        uint256[] memory totals = new uint256[](categories.length);
        for (uint256 i = 0; i < categories.length; i++) {
            totals[i] = nft.totalCategoryIds(controller, categories[i]);
        }
        return (categories, totals);
    }

    function nftBatch(
        address account,
        uint256[][] memory ids,
        address controller,
        int256[] memory categories,
        uint256[] memory skips,
        uint256[] memory totals,
        address[] calldata spenders
    )
        external
        view
        returns (INFT.NftExtended[] memory)
    {
        if(ids.length == 0) {
            ids = nft.categoriesIdBatch(
                controller,
                categories,
                skips,
                totals
            );
        }

        uint256 c;
        for (uint256 i = 0; i < ids.length; i++) c += ids[i].length;
        return _nftBatch(ids, c, account, spenders);
    }

    function _nftBatch(
        uint256[][] memory ids,
        uint256 c,
        address account,
        address[] calldata spenders
    )
        internal
        view
        returns (INFT.NftExtended[] memory)
    {
        INFT.NftExtended[] memory nfts_ = new INFT.NftExtended[](c);
        c = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            INFT.Nft[] memory nfts = nft.nftBatch(ids[i], account);

            uint256[7][][2] memory datas = _dataBatch(nfts);
            for (uint256 y = 0; y < ids[i].length; y++) {
                if(ids[i][y] > 0) {
                    nfts_[c] = _nftExtended(
                        nfts[y],
                        account,
                        spenders,

                        [datas[0][y], datas[1][y]]
                    );
                }
                c++;
            }
        }
        return nfts_;
    }

    function nftFilteredBatch(
       address account,
       address[] calldata controllers_,
       int256[][] calldata categories,
       address[] calldata spenders
    )
       external
       view
       returns (INFT.NftExtended[] memory)
    {
        INFT.Nft[] memory nfts = nft.nftBatch(
            nft.idBatch(account, controllers_, categories),
            account
        );
        INFT.NftExtended[] memory nfts_ = new INFT.NftExtended[](nfts.length);
        if(nfts.length == 0) return nfts_;

        uint256[7][][2] memory datas = _dataBatch(nfts);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts_[i] = _nftExtended(
                nfts[i],
                account,
                spenders,

                [datas[0][i], datas[1][i]]
            );
        }
        return nfts_;
    }

    function niftyDataBatch(
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[7][] memory)
    {
        return _niftyDataBatch(
            nft.nftBatch(ids, address(0)),
            nifty.getGlobalRoyaltyFee()
        );
    }

    function _dataBatch(
        INFT.Nft[] memory nfts
    )
        internal
        view
        returns (uint256[7][][2] memory)
    {
        return [
            _powerDataBatch(nfts),
            _niftyDataBatch(nfts, nifty.getGlobalRoyaltyFee())
        ];
    }

    function _powerDataBatch(
        INFT.Nft[] memory nfts
    )
        internal
        view
        returns (uint256[7][] memory)
    {
        uint256[7][] memory datas = new uint256[7][](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            if(nfts[i].controller != controllers[0] || nfts[i].category < 0) continue;
            (
                , //address,
                , // address,
                , // uint256,
                , // uint256,
                , // uint256,
                , // uint256,
                , // uint256,
                address vault
            ) = abi.decode(nfts[i].params, (address, address, uint256, uint256, uint256, uint256, uint256, address));
            datas[i][5] = governanceToken.balanceOf(vault);
        }
        return datas;
    }

    function _niftyDataBatch(
        INFT.Nft[] memory nfts,
        uint256 royaltyFee
    )
        internal
        view
        returns (uint256[7][] memory)
    {
        uint256[7][] memory datas = new uint256[7][](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            if(nfts[i].controller != controllers[1]) continue;
            uint256[] memory ids;
            if(nfts[i].category < 0) {
                (
                    , //address,
                    , // address,
                    , // uint256,
                    , // uint256,
                    , // uint256,
                    , // uint256,
                    , // uint256,
                    ids
                ) = abi.decode(nfts[i].params, (address, address, uint256, uint256, uint256, uint256, uint256, uint256[]));
            } else {
                ids = new uint256[](1);
                ids[0] = nfts[i].id;

                datas[i][0] = nft.balanceOf(address(nifty), ids[0]);
                datas[i][1] = nifty.getCurrencyReserves(ids)[0];
            }
            uint256[] memory amounts = new uint256[](ids.length);
            for (uint256 y = 0; y < ids.length; y++) amounts[y] = 1;

            uint256 buyPrice; uint256 sellPrice;
            uint256[] memory buyPrices = nifty.getPrice_currencyToToken(ids, amounts);
            uint256[] memory sellPrices = nifty.getPrice_tokenToCurrency(ids, amounts);
            bool hasBuyPriceZero;
            for (uint256 y = 0; y < ids.length; y++) {
                if(buyPrices[y] == 0) hasBuyPriceZero = true;
                buyPrice += buyPrices[y];
                sellPrice += sellPrices[y];
            }
            datas[i][2] = (!hasBuyPriceZero) ? buyPrice : 0;
            datas[i][3] = sellPrice;

            datas[i][6] = royaltyFee;
        }
        return datas;
    }

    function _nftExtended(
        INFT.Nft memory nft_,
        address account,
        address[] calldata spenders,
        uint256[7][2] memory datas
    )
        internal
        view
        returns (INFT.NftExtended memory)
    {
        uint256 reserveNft;
        uint256 reserveToken;
        uint256 buyPriceToken;
        uint256 sellPriceToken;
        uint256 buyPriceGovernanceToken;
        uint256 sellPriceGovernanceToken;
        uint256 royaltyPermille;

        if(nft_.controller == controllers[0]) {
            reserveNft = datas[0][0];
            reserveToken = datas[0][1];
            buyPriceToken = datas[0][2];
            sellPriceToken = datas[0][3];
            buyPriceGovernanceToken = datas[0][4];
            sellPriceGovernanceToken = datas[0][5];
            royaltyPermille = datas[0][6];
        } else if(nft_.controller == controllers[1]) {
            reserveNft = datas[1][0];
            reserveToken = datas[1][1];
            buyPriceToken = datas[1][2];
            sellPriceToken = datas[1][3];
            buyPriceGovernanceToken = datas[1][4];
            sellPriceGovernanceToken = datas[1][5];
            royaltyPermille = datas[1][6];
        }

        return INFT.NftExtended({
            id: nft_.id,
            index: nft_.index,
            edition: nft_.edition,
            total: nft_.total,
            balance: nft_.balance,
            createdAt: nft_.createdAt,
            updatedAt: nft_.updatedAt,
            category: nft_.category,
            controller: nft_.controller,
            params: nft_.params,

            tokenAmountUnclaimed: _unclaimed(nft_),

            reserveNft: reserveNft,
            reserveToken: reserveToken,

            buyPriceToken: buyPriceToken,
            sellPriceToken: sellPriceToken,

            buyPriceGovernanceToken: buyPriceGovernanceToken,
            sellPriceGovernanceToken: sellPriceGovernanceToken,

            royaltyPermille: royaltyPermille,

            approved: nft.isApprovedForAllBatch(account, spenders)
        });
    }

    function _unclaimed(
        INFT.Nft memory nft_
    )
        internal
        view
        returns (uint256)
    {
        if(nft_.params.length == 0) return 0;

        (
            , // address owner
            , // address delegatee
            uint256 delay,
            uint256 numerator,
            uint256 blockNumber
        ) = abi.decode(nft_.params, (address, address, uint256, uint256, uint256));

        return masterchief.unclaimed(
            nft_.controller,
            address(uint160(nft_.id)),
            blockNumber,
            delay,
            numerator,
            IController(nft_.controller).denominator()
        );
    }

    function _buyPriceUSDC(
        uint256 amountOut,
        uint256 reserveToken0,
        uint256 reserveToken1
    )
        internal
        pure
        returns (uint256)
    {
        if(reserveToken0 == 0 || reserveToken1 == 0) return 0;
        return _getAmountIn(amountOut, reserveToken1, reserveToken0);
    }

    function _sellPriceUSDC(
        uint256 amountIn,
        uint256 reserveToken0,
        uint256 reserveToken1
    )
        internal
        pure
        returns (uint256)
    {
        if(reserveToken0 == 0 || reserveToken1 == 0) return 0;
        return _getAmountOut(amountIn, reserveToken0, reserveToken1);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    )
        internal
        pure
        returns (uint256 amountIn)
    {
        if(amountOut >= reserveOut) return 0;
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function _allowances(
        IToken token,
        address account,
        address[] calldata spenders
    )
        internal
        view returns (IToken.Allowance[] memory)
    {
        if(account == address(0)) return new IToken.Allowance[](0);

        IToken.Allowance[] memory allowances_ = new IToken.Allowance[](spenders.length);
        for (uint256 i = 0; i < spenders.length; i++) {
            allowances_[i] = IToken.Allowance({
              spender: spenders[i],
              amount: token.allowance(account, spenders[i])
            });
        }
        return allowances_;
    }

    function _token(
        IFactory factory,
        address[] memory path,
        address WETH9
    )
        internal
        view returns (IToken.Token memory)
    {
        uint256 reserveToken0; uint256 reserveToken1;
        uint256 reserveNativeToken0; uint256 reserveNativeToken1;
        uint256 lp;

        if(path.length > 1) {
            IPair pair = IPair(factory.getPair(
                 path[path.length - 2],
                 path[path.length - 1]
            ));
            lp = pair.totalSupply();

            (reserveToken0, reserveToken1, ) = pair.getReserves();
            if(pair.token0() != path[path.length - 1]) {
                (reserveToken0, reserveToken1) = (reserveToken1, reserveToken0);
            }

            if(path.length == 2) {
               (reserveToken0, reserveToken1) = (reserveToken1, reserveToken0);
            }

            if(path[path.length - 1] != WETH9) {
                IPair pairNative = IPair(factory.getPair(
                    path[path.length - 1],
                    WETH9
                ));
                (reserveNativeToken0, reserveNativeToken1, ) = pairNative.getReserves();
                if(pairNative.token0() != path[path.length - 1]) {
                    (reserveNativeToken0, reserveNativeToken1) = (reserveNativeToken1, reserveNativeToken0);
                }
            }
        }

        return IToken.Token({
            pathId: 0,
            path: path,
            decimals: 0,
            totalSupply: 0,

            reserveToken0: reserveToken0,
            reserveToken1: reserveToken1,
            reserveNativeToken0: reserveNativeToken0,
            reserveNativeToken1: reserveNativeToken1,
            lp: lp,

            buyPriceUSDC: 0,
            sellPriceUSDC: 0,

            sellTaxPermille: 0,
            balance: 0,
            allowances: new IToken.Allowance[](0)
        });

    }

    function _governanceToken(
        IFactory factory,
        address[] memory path,
        address account,
        address[] calldata spenders
    )
        internal
        view returns (IToken.Token memory)
    {
        IPair pair = IPair(factory.getPair(path[0], path[1]));
        (uint256 reserveToken0, uint256 reserveToken1, ) = pair.getReserves();

        if(pair.token0() != path[0]) {
            (reserveToken0, reserveToken1) = (reserveToken1, reserveToken0);
        }

        uint256 lp = pair.balanceOf(address(masterchief));
        reserveToken1 = reserveToken1 * lp / pair.totalSupply();

        IToken token = IToken(masterchief.governanceToken());

        uint256 circulatingSupply = token.circulatingSupply();
        path = new address[](1); path[0] = address(token);
        uint256 price = reserveToken1 * 10**18 / circulatingSupply;

        return IToken.Token({
            pathId: -1,
            path: path,
            decimals: 18,
            totalSupply: token.totalSupply(),
            reserveToken0: 0,
            reserveToken1: reserveToken1,
            reserveNativeToken0: 0,
            reserveNativeToken1: 0,
            lp: lp,
            buyPriceUSDC: price,
            sellPriceUSDC: price,
            sellTaxPermille: masterchief.sellTaxPermille(),
            balance: (account != address(0)) ? token.balanceOf(account) : 0,
            allowances: _allowances(token, account, spenders)
        });
    }

    function balanceOfBatch(
        address account,
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IToken(tokens[i]).balanceOf(account);
        }
        return balances;
    }

    function approve()
        external
    {
        address[][] memory paths = masterchief.pathBatch();
        address router = masterchief.router();
        for (uint256 i = 0; i < paths.length; i++) {
            IToken(paths[i][paths[i].length - 1]).approve(router, 0);
            IToken(paths[i][paths[i].length - 1]).approve(router, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}