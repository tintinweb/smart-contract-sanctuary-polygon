// SPDX-License-Identifier: BUSL-1.1
/*
 * Black-Scholes based CFMM class for poption
 * Copyright ©2022 by Poption.org.
 * Author: Poption <[email protected]>
 */
pragma solidity ^0.8.4;

import "./Math.sol";
import "./Poption.sol";
import "./BaseCFMMSwap.sol";
import "./interface/IOracle.sol";

contract BlackScholesSwap is BaseCFMMSwap {
    using Math64x64 for uint128;
    using Math64x64 for int128;
    uint128 public volatility;
    int128[STRIKE_NUM] public lnStrikes;
    bool public isCash;

    constructor(
        address _owner,
        address _poption,
        uint256 _closeTime,
        uint256 _destoryTime,
        uint128 _feeRate,
        uint128 _l2FeeRate,
        uint128 _volatility,
        bool _isCash
    )
        BaseCFMMSwap(
            _owner,
            _poption,
            _closeTime,
            _destoryTime,
            _feeRate,
            _l2FeeRate
        )
    {
        volatility = _volatility;
        isCash = _isCash;
    }

    function init() external override noReentrant {
        require(!_isInited, "INITED");
        _isInited = true;
        super._init();
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            lnStrikes[i] = strikes[i].ln();
        }
    }

    function getWeight()
        public
        view
        override
        returns (uint128[STRIKE_NUM] memory weight)
    {
        if (block.timestamp < settleTime) {
            uint128 price = IOracle(oracle).get();
            int128 std = int128(
                volatility.mul(
                    (uint128((settleTime - block.timestamp) << 64)).sqrt()
                )
            );
            weight = getWeightBS(price, std);
        } else {
            weight = getWeightAfterSettle();
        }
    }

    function getWeightBS(uint128 price, int128 std)
        internal
        view
        returns (uint128[STRIKE_NUM] memory weight)
    {
        int128 lnPriceDivStd = price.ln().div(std);
        int128 bias0;
        int128 bias1;
        uint128 scale;
        if (isCash) {
            bias0 = lnPriceDivStd - std / 2;
            bias1 = lnPriceDivStd + std / 2;
            scale = price;
        } else {
            bias0 = lnPriceDivStd + std / 2;
            bias1 = lnPriceDivStd + (std * 3) / 2;
            scale = price.mul(uint128(std.mul(std)).exp());
        }
        uint256 i;
        int128 x = lnStrikes[0].div(std);
        uint128 a0 = Math64x64.normCdf(x - bias0);
        uint128 t0 = Math64x64.normCdf(x - bias1).mul(scale);
        weight[0] = a0;
        for (i = 1; i < STRIKE_NUM; i++) {
            x = lnStrikes[i].div(std);
            uint128 a1 = Math64x64.normCdf(x - bias0);
            uint128 t1 = Math64x64.normCdf(x - bias1).mul(scale);
            uint128 gap = strikes[i] - strikes[i - 1];
            uint128 aa = (a1 - a0).mul(strikes[i]) + t0;
            if (aa < t1) {
                weight[i - 1] += 0;
            } else {
                weight[i - 1] += (aa - t1).div(gap);
            }
            aa = (a1 - a0).mul(strikes[i - 1]) + t0;
            if (aa > t1) {
                weight[i] = 0;
            } else {
                weight[i] = (t1 - aa).div(gap);
            }
            a0 = a1;
            t0 = t1;
        }
        weight[STRIKE_NUM - 1] += 0x10000000000000000 - a0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Math 64x64 Smart Contract Library.
 * Copyright ©2022 by Poption.org.
 * Author: Hydrogenbear <[email protected]>
 */

pragma solidity ^0.8.4;

library Math64x64 {
    uint256 internal constant ONE = 0x10000000000000000;
    uint256 internal constant ONEONE = 0x100000000000000000000000000000000;
    uint256 internal constant MAX128 = 0xffffffffffffffffffffffffffffffff;

    function mul(int256 x, int256 y) internal pure returns (int128 r) {
        assembly {
            r := sar(64, mul(x, y))
            if and(
                gt(r, 0x7fffffffffffffffffffffffffffffff),
                lt(
                    r,
                    0xffffffffffffffffffffffffffffffff80000000000000000000000000000000
                )
            ) {
                revert(0, 0)
            }
        }
    }

    function mul(uint128 x, uint128 y) internal pure returns (uint128 r) {
        assembly {
            r := shr(64, mul(x, y))
            if gt(r, MAX128) {
                revert(0, 0)
            }
        }
    }

    function div(uint128 x, uint128 y) internal pure returns (uint128 r) {
        assembly {
            r := div(shl(64, x), y)
            if gt(r, MAX128) {
                revert(0, 0)
            }
        }
    }

    function div(int128 x, int128 y) internal pure returns (int128 r) {
        assembly {
            if iszero(y) {
                revert(0, 0)
            }
            r := sdiv(shl(64, x), y)
            if and(
                gt(r, 0x7fffffffffffffffffffffffffffffff),
                lt(
                    r,
                    0xffffffffffffffffffffffffffffffff80000000000000000000000000000000
                )
            ) {
                revert(0, 0)
            }
        }
    }

    function msb(int128 x) internal pure returns (int128 r) {
        require(x >= 0, "No Neg");
        unchecked {
            return msb(uint128(x));
        }
    }

    function msb(uint128 x) internal pure returns (int128 r) {
        assembly {
            let j := mul(gt(x, 0xffffffffffffffff), 0x40)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0xffffffff), 0x20)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0xffff), 0x10)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0xff), 0x8)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0xf), 0x4)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0x3), 0x2)
            x := shr(j, x)
            r := add(j, r)

            j := mul(gt(x, 0x1), 0x1)
            x := shr(j, x)
            r := add(j, r)
        }
    }

    function ln(uint128 rx) internal pure returns (int128) {
        require(rx > 0, "Be Pos");
        unchecked {
            int256 r = msb(rx);

            assembly {
                let x := shl(sub(127, r), rx)
                r := sar(
                    50,
                    mul(
                        sub(r, 63),
                        265561240842969827543796575331103159507101128947518051
                    )
                )
                if lt(x, 0xb504f333f9de6484597d89b3754abe9f) {
                    x := shr(128, mul(x, 0x16a09e667f3bcc908b2fb1366ea957d3e))
                    r := sub(r, 0x58b90bfbe8e7bcd5e4f1d9cc01f97b58)
                }

                if lt(x, 0xd744fccad69d6af439a68bb9902d3fde) {
                    x := shr(128, mul(x, 0x1306fe0a31b7152de8d5a46305c85eded))
                    r := sub(r, 0x2c5c85fdf473de6af278ece600fcbdac)
                }

                if lt(x, 0xeac0c6e7dd24392ed02d75b3706e54fb) {
                    x := shr(128, mul(x, 0x1172b83c7d517adcdf7c8c50eb14a7920))
                    r := sub(r, 0x162e42fefa39ef35793c7673007e5ed6)
                }

                if lt(x, 0xf5257d152486cc2c7b9d0c7aed980fc4) {
                    x := shr(128, mul(x, 0x10b5586cf9890f6298b92b71842a98364))
                    r := sub(r, 0xb17217f7d1cf79abc9e3b39803f2f6b)
                }

                if lt(x, 0xfa83b2db722a033a7c25bb14315d7fcd) {
                    x := shr(128, mul(x, 0x1059b0d31585743ae7c548eb68ca417ff))
                    r := sub(r, 0x58b90bfbe8e7bcd5e4f1d9cc01f97b6)
                }

                if lt(x, 0xfd3e0c0cf486c174853f3a5931e0ee03) {
                    x := shr(128, mul(x, 0x102c9a3e778060ee6f7caca4f7a29bde9))
                    r := sub(r, 0x2c5c85fdf473de6af278ece600fcbdb)
                }

                let m := div(
                    shl(128, sub(0x100000000000000000000000000000000, x)),
                    add(0x100000000000000000000000000000000, x)
                )
                let im := m
                let rr := m
                m := shr(128, mul(m, m))
                for {
                    let i := 3
                } gt(im, 0x10000000000000000) {
                    i := add(i, 6)
                } {
                    im := shr(128, mul(im, m))
                    rr := add(rr, div(im, i))
                    im := shr(128, mul(im, m))
                    rr := add(rr, div(im, add(i, 2)))
                    im := shr(128, mul(im, m))
                    rr := add(rr, div(im, add(i, 4)))
                }
                r := sar(64, sub(r, shl(1, rr)))
            }
            return int128(r);
        }
    }

    function sqrt(uint128 x) internal pure returns (uint128 r) {
        unchecked {
            int128 msbx = msb(x);
            assembly {
                let rx := shl(64, x)
                r := shr(add(32, sar(1, msbx)), rx)
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
            }
        }
    }

    function normCdf(int128 x) internal pure returns (uint128 r) {
        assembly {
            let sgn := 1
            if gt(
                x,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            ) {
                x := sub(0, x)
                sgn := 0
            }
            switch gt(x, 0x927c1552af58a0000)
            case 1 {
                r := 0
            }
            default {
                r := sar(64, mul(x, 0x5a4fb39ac251))
                r := sar(64, mul(x, add(r, 0x3343fae611b8a)))
                r := sar(64, mul(x, add(r, 0x27d981c9c0bf2)))
                r := sar(64, mul(x, add(r, 0xd6cd71dee78ea0)))
                r := sar(64, mul(x, add(r, 0x5697f3a04cf1580)))
                r := sar(64, mul(x, add(r, 0xcc41b405c539100)))
                r := add(r, 0x10000000000000000)
                r := sar(64, mul(r, r))
                r := sar(64, mul(r, r))
                r := sar(64, mul(r, r))
                r := sar(64, mul(r, r))
                r := div(0x80000000000000000000000000000000, r)
            }
            if sgn {
                r := sub(0x10000000000000000, r)
            }
        }
    }

    function cauchyCdf(int128 x) internal pure returns (uint128 r) {
        assembly {
            r := x
            let sgn := 1
            if gt(
                r,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            ) {
                r := sub(0, r)
                sgn := 0
            }
            let inv := 1
            if gt(r, 0x10000000000000000) {
                r := div(0x100000000000000000000000000000000, r)
                inv := 0
            }
            let x2_ := sar(64, mul(r, r))
            let y := sub(sar(64, mul(2124161823823364, x2_)), 16640283787842336)
            y := add(sar(64, mul(y, x2_)), 61222568753354112)
            y := sub(sar(64, mul(y, x2_)), 143277719382150352)
            y := add(sar(64, mul(y, x2_)), 246608687101375616)
            y := sub(sar(64, mul(y, x2_)), 346968386593137216)
            y := add(sar(64, mul(y, x2_)), 437013696018853440)
            y := sub(sar(64, mul(y, x2_)), 530379345809171520)
            y := add(sar(64, mul(y, x2_)), 651880698001138560)
            y := sub(sar(64, mul(y, x2_)), 838771940666329344)
            y := add(sar(64, mul(y, x2_)), 1174353130486501120)
            y := sub(sar(64, mul(y, x2_)), 1957260253410140928)
            y := add(sar(64, mul(y, x2_)), 5871781005908458496)
            r := sar(64, mul(y, r))

            if xor(sgn, inv) {
                r := add(sub(0, r), 0x8000000000000000)
            }
            if sgn {
                r := add(r, 0x8000000000000000)
            }
        }
    }

    function exp(uint128 x) internal pure returns (uint128 r) {
        require(x < 0x2bab13e5fca20ef146, "Overflow");
        if (x == 0) {
            return 0x10000000000000000;
        }
        assembly {
            let k := add(
                div(shl(64, x), 0xb17217f7d1cf79ab),
                0x7fffffffffffffff
            )
            k := sar(64, k)
            let rr := sub(x, mul(k, 0xb17217f7d1cf79ab))

            r := 0x10000000000000000
            for {
                let i := 0x12
            } gt(i, 0) {
                i := sub(i, 1)
            } {
                r := add(sar(64, mul(r, sdiv(rr, i))), 0x10000000000000000)
            }
            r := shl(k, r)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Poption contract
 * Copyright ©2022 by Poption.
 * Author: Hydrogenbear <[email protected]>
 */
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "./StrikeNum.sol";
import "./interface/IOracle.sol";
import "./interface/ISwap.sol";
import "./Math.sol";

contract Poption is IERC1155 {
    using Math64x64 for uint128;

    uint128[STRIKE_NUM] public strikes;
    uint256[] public allIds;
    mapping(address => uint128[STRIKE_NUM]) public options;
    mapping(bytes32 => bool) public usedHash;
    mapping(address => mapping(address => bool)) private approval;
    uint128 public totalLockedAsset;

    IOracle public immutable oracle;
    uint256 public immutable settleTime;
    address public immutable token;
    bytes4 private constant SELECTOR_TRANSFERFROM =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bool internal locked;

    bool public isSettled;
    uint8 public settleIdx;
    uint128 public settleWeight0;
    uint128 public settleWeight1;

    event Settle(uint128 price);
    event Mint(address owner, uint128 asset);

    event Burn(address owner, uint128 asset);

    event CreatePoption(
        address indexed token,
        address indexed oracle,
        uint256 settleTime,
        uint128[STRIKE_NUM] strikes
    );

    event ExercisePoption(uint128 asset, uint128 tail);

    constructor(
        address _token,
        address _oracle,
        uint256 _settleTime,
        uint128[STRIKE_NUM] memory _strikes
    ) {
        token = _token;
        oracle = IOracle(_oracle);
        settleTime = _settleTime;
        strikes = _strikes;
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            allIds.push(i);
        }
        emit CreatePoption(_token, _oracle, _settleTime, _strikes);
    }

    function getState()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint128[STRIKE_NUM] memory
        )
    {
        return (token, address(oracle), settleTime, strikes);
    }

    modifier noReentrant() {
        require(!locked, "REEN");
        locked = true;
        _;
        locked = false;
    }

    function settle() public {
        unchecked {
            if ((!isSettled) && (block.timestamp > settleTime)) {
                uint128 price = oracle.get();
                isSettled = true;
                if (price <= strikes[0]) {
                    settleIdx = 1;
                    settleWeight0 = uint128(Math64x64.ONE);
                    settleWeight1 = 0;
                } else if (price >= strikes[STRIKE_NUM - 1]) {
                    settleIdx = uint8(STRIKE_NUM - 1);
                    settleWeight0 = 0;
                    settleWeight1 = uint128(Math64x64.ONE);
                } else {
                    uint8 h = uint8(STRIKE_NUM - 1);
                    uint8 l = 0;
                    settleIdx = (h + l) >> 1;
                    while (h > l) {
                        if (strikes[settleIdx] >= price) {
                            h = settleIdx;
                        } else {
                            l = settleIdx + 1;
                        }
                        settleIdx = (h + l) >> 1;
                    }
                    uint128 delta = strikes[settleIdx] - strikes[settleIdx - 1];
                    settleWeight0 = (strikes[settleIdx] - price).div(delta);
                    settleWeight1 = uint128(Math64x64.ONE) - settleWeight0;
                }
                emit Settle(price);
            }
            require(isSettled, "NSET");
        }
    }

    function balanceOfAll(address addr)
        external
        view
        returns (uint128[STRIKE_NUM] memory)
    {
        return options[addr];
    }

    function _safeTokenTransferFrom(
        address token_,
        address from_,
        address to_,
        uint256 value_
    ) private {
        (bool success, bytes memory data) = token_.call(
            abi.encodeWithSelector(SELECTOR_TRANSFERFROM, from_, to_, value_)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TE"
            // transfer error
        );
    }

    function _safeTokenTransfer(
        address token_,
        address to_,
        uint256 value_
    ) private {
        (bool success, bytes memory data) = token_.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to_, value_)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TE"
            // transfer error
        );
    }

    function _transfer(
        address _from,
        address _to,
        uint128[STRIKE_NUM] memory _option
    ) private {
        require(_to != address(0), "T0Addr");
        uint256[] memory value = new uint256[](STRIKE_NUM);
        unchecked {
            for (uint256 i = 0; i < STRIKE_NUM; i++) {
                uint128 amount = _option[i];
                if (amount > 0) {
                    require(amount <= options[_from][i], "NEO");
                    options[_to][i] += amount;
                    options[_from][i] -= amount;
                    value[i] = amount;
                }
            }
            emit TransferBatch(msg.sender, _from, _to, allIds, value);
        }
    }

    function transfer(address _recipient, uint128[STRIKE_NUM] calldata _option)
        external
    {
        _transfer(msg.sender, _recipient, _option);
    }

    function mint(uint128 _asset) public noReentrant {
        _safeTokenTransferFrom(token, msg.sender, address(this), _asset);
        uint256[] memory value = new uint256[](STRIKE_NUM);
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            options[msg.sender][i] += _asset;
        }
        totalLockedAsset += _asset;
        emit TransferBatch(msg.sender, address(0), msg.sender, allIds, value);
        emit Mint(msg.sender, _asset);
    }

    function burn(uint128 _asset) public noReentrant {
        uint256[] memory value = new uint256[](STRIKE_NUM);
        unchecked {
            for (uint256 i = 0; i < STRIKE_NUM; i++) {
                require(_asset <= options[msg.sender][i], "NEO");
                options[msg.sender][i] -= _asset;
                value[i] = _asset;
            }
        }
        _safeTokenTransfer(token, address(msg.sender), uint256(_asset));
        totalLockedAsset -= _asset;
        emit TransferBatch(msg.sender, msg.sender, address(0), allIds, value);
        emit Burn(msg.sender, _asset);
    }

    function outSwap(
        address marketMaker,
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in,
        uint128 _assert,
        bool _isMint
    ) external {
        if (_isMint) {
            mint(_assert);
        }
        swap(marketMaker, _out, _in);
        if (!_isMint) {
            burn(_assert);
        }
    }

    function swap(
        address marketMaker,
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) public noReentrant {
        _transfer(marketMaker, msg.sender, _out);
        _transfer(msg.sender, marketMaker, _in);
        ISwap(marketMaker).onSwap(_out, _in);
    }

    function liquidIn(address marketMaker, uint128 frac) external noReentrant {
        uint128[STRIKE_NUM] memory option;
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            option[i] = options[marketMaker][i].mul(frac);
        }
        _transfer(msg.sender, marketMaker, option);
        ISwap(marketMaker).onLiquidIn(frac, msg.sender);
    }

    function exercise() external {
        exerciseTail(0);
    }

    function exerciseTail(uint128 tail) public noReentrant {
        settle();
        uint128 asset = options[msg.sender][settleIdx - 1].mul(settleWeight0) +
            options[msg.sender][settleIdx].mul(settleWeight1) -
            tail;
        uint256[] memory value = new uint256[](STRIKE_NUM);
        value[settleIdx - 1] = options[msg.sender][settleIdx - 1];
        value[settleIdx] = options[msg.sender][settleIdx];

        options[msg.sender][settleIdx - 1] = 0;
        options[msg.sender][settleIdx] = 0;
        _safeTokenTransfer(token, address(msg.sender), asset);
        totalLockedAsset -= asset;
        emit TransferBatch(msg.sender, msg.sender, address(0), allIds, value);
        emit ExercisePoption(asset, tail);
    }

    /** ERC1155 interface */

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address addr, uint256 i)
        external
        view
        returns (uint256)
    {
        return options[addr][i];
    }

    function balanceOfBatch(
        address[] calldata _accounts,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory) {
        require(_accounts.length == _ids.length, "ERC1155: length mismatch");

        uint256[] memory batchBalances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; ++i) {
            batchBalances[i] = options[_accounts[i]][_ids[i]];
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        approval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return approval[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "NO APPROVAL"
        );
        require(to != address(0), "ZERO ADDRESS");
        require(id < STRIKE_NUM, "WRONG ID");
        require(amount <= options[from][id], "NE BA");
        options[to][id] += uint128(amount);
        unchecked {
            options[from][id] -= uint128(amount);
        }
        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(to != address(0), "ZERO ADDRESS");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "NO APPROVAL"
        );
        require(ids.length == amounts.length, "LEN MM");
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            require(id < STRIKE_NUM, "WRONG ID");
            require(amount <= options[from][id], "NE BA");
            options[to][id] += uint128(amount);
            unchecked {
                options[from][id] -= uint128(amount);
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    // Below Code Adapted From openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Base CFMM class for poption
 * Copyright ©2022 by Poption.org.
 * Author: Poption <[email protected]>
 */
pragma solidity ^0.8.4;

import "./Math.sol";
import "./Poption.sol";
import "./StrikeNum.sol";
import "./interface/IOracle.sol";
import "./interface/ISwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BaseCFMMSwap is ISwap, IERC20Metadata {
    using Math64x64 for uint128;
    using Math64x64 for int128;

    uint128[STRIKE_NUM] public strikes;
    uint128[STRIKE_NUM] public liqPool;
    mapping(address => uint128) public liqPoolShare;
    uint128 public liqPoolShareAll;
    mapping(address => uint128) public valueNoFee;
    mapping(address => mapping(address => uint256)) public allowances;

    address public immutable oracle;
    Poption public immutable poption;
    address public immutable owner;
    uint256 public immutable closeTime;
    uint256 public immutable settleTime;
    uint256 public immutable destroyTime;

    bool internal locked;
    uint128 public feeRate;
    uint128 public l2FeeRate;

    bool internal _isInited;
    string public symbol;
    string public name;
    uint8 public decimals;

    event Swap(
        uint128[STRIKE_NUM] _in,
        uint128[STRIKE_NUM] _out,
        uint128[STRIKE_NUM] weight,
        uint128[STRIKE_NUM] liqPool
    );

    event Mint(
        address owner,
        uint128 share,
        uint128 shareAll,
        uint128[STRIKE_NUM] liqPool
    );

    event Burn(
        address owner,
        uint128 share,
        uint128 shareAll,
        uint128[STRIKE_NUM] liqPool
    );

    constructor(
        address _owner,
        address _poption,
        uint256 _closeTime,
        uint256 _destroyTime,
        uint128 _feeRate,
        uint128 _l2FeeRate
    ) {
        owner = _owner;
        poption = Poption(_poption);
        address token;
        uint256 _settleTime;
        (token, oracle, _settleTime, strikes) = Poption(_poption).getState();
        require(_closeTime < _settleTime && _settleTime < _destroyTime, "TCK");
        closeTime = _closeTime;
        settleTime = _settleTime;
        destroyTime = _destroyTime;
        feeRate = _feeRate;
        l2FeeRate = _l2FeeRate;
        symbol = "";
        name = "";
        decimals = IERC20Metadata(token).decimals();
    }

    modifier noReentrant() {
        require(!locked, "RE");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OO");
        _;
    }

    modifier onlyPoption() {
        require(msg.sender == address(poption), "OP");
        _;
    }

    function getWeight()
        public
        view
        virtual
        returns (uint128[STRIKE_NUM] memory weight)
    {
        if (block.timestamp < settleTime) {
            unchecked {
                for (uint256 i = 0; i < STRIKE_NUM; i++) {
                    weight[i] = uint128(Math64x64.ONE / STRIKE_NUM);
                }
            }
        } else {
            weight = getWeightAfterSettle();
        }
    }

    function _init() internal {
        uint128[STRIKE_NUM] memory _option = poption.balanceOfAll(
            address(this)
        );
        uint128 share;
        for (uint256 i; i < STRIKE_NUM; i++) {
            require(_option[i] > 100, "TL");
            liqPool[i] = _option[i];
            share += _option[i];
        }
        share = share / uint128(STRIKE_NUM);
        liqPoolShare[owner] += share;
        valueNoFee[owner] = 0x7fffffffffffffffffffffffffffffff;
        liqPoolShareAll += share;
    }

    function init() external virtual noReentrant {
        require(!_isInited, "INITED");
        _isInited = true;
        _init();
    }

    function getStatus()
        external
        view
        returns (
            uint128[STRIKE_NUM] memory,
            uint128[STRIKE_NUM] memory,
            uint128
        )
    {
        return (getWeight(), liqPool, feeRate);
    }

    function tradeDiff(
        uint128[STRIKE_NUM] memory liq,
        uint128[STRIKE_NUM] memory to,
        uint128[STRIKE_NUM] memory w
    ) internal pure returns (int128 res) {
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            res += ((to[i]).ln() - (liq[i]).ln()).mul(int128(w[i]));
        }
    }

    function getWeightAfterSettle()
        internal
        view
        returns (uint128[STRIKE_NUM] memory weight)
    {
        uint8 settleIdx;
        uint128 settleWeight0;
        uint128 settleWeight1;
        if (poption.isSettled()) {
            settleIdx = poption.settleIdx();
            settleWeight0 = poption.settleWeight0();
            settleWeight1 = poption.settleWeight1();
        } else {
            uint128 price = IOracle(oracle).get();
            if (price <= strikes[0]) {
                settleIdx = 1;
                settleWeight0 = uint128(Math64x64.ONE);
                settleWeight1 = 0;
            } else if (price >= strikes[STRIKE_NUM - 1]) {
                settleIdx = uint8(STRIKE_NUM - 1);
                settleWeight0 = 0;
                settleWeight1 = uint128(Math64x64.ONE);
            } else {
                uint8 h = uint8(STRIKE_NUM - 1);
                uint8 l = 0;
                settleIdx = (h + l) >> 1;
                while (h > l) {
                    if (strikes[settleIdx] >= price) {
                        h = settleIdx;
                    } else {
                        l = settleIdx + 1;
                    }
                    settleIdx = (h + l) >> 1;
                }
                uint128 delta = strikes[settleIdx] - strikes[settleIdx - 1];
                settleWeight0 = (strikes[settleIdx] - price).div(delta);
                settleWeight1 = (price - strikes[settleIdx - 1]).div(delta);
            }
        }
        uint128 p0 = settleWeight0.mul(liqPool[settleIdx - 1]);
        uint128 p1 = settleWeight1.mul(liqPool[settleIdx]);
        weight[settleIdx - 1] = p0.div(p0 + p1);
        weight[settleIdx] = p1.div(p0 + p1);
    }

    function _onSwap(
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) internal virtual {
        uint128[STRIKE_NUM] memory weight = getWeight();
        uint128[STRIKE_NUM] memory lpTo;
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            uint128 outi = _out[i].mul(feeRate);
            require(liqPool[i] > outi, "PLQ");
            lpTo[i] = liqPool[i] + _in[i].div(feeRate) - outi;
        }
        require(tradeDiff(liqPool, lpTo, weight) >= 0, "PMC");
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            liqPool[i] = liqPool[i] + _in[i] - _out[i];
        }
        emit Swap(_in, _out, weight, liqPool);
    }

    function toSwap(
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) external noReentrant onlyPoption {
        require(_isInited && block.timestamp < closeTime, "MCT");
        _onSwap(_out, _in);
    }

    function onSwap(
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) external noReentrant onlyPoption {
        require(_isInited && block.timestamp < closeTime, "MCT");
        _onSwap(_out, _in);
    }

    function _onLiquidIn(uint128 _frac, address _sender) internal {
        uint128 priceDivisor = 0;
        uint128 shareAdd = _frac.mul(liqPoolShareAll);
        liqPoolShareAll += shareAdd;
        liqPoolShare[_sender] += shareAdd;
        emit Transfer(address(0), _sender, shareAdd);
        uint128[STRIKE_NUM] memory weight = getWeight();
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            priceDivisor += uint128(weight[i]).div(liqPool[i]);
            liqPool[i] += _frac.mul(liqPool[i]);
        }
        valueNoFee[_sender] += _frac.div(priceDivisor);
        emit Mint(_sender, shareAdd, liqPoolShareAll, liqPool);
    }

    function toLiquidIn(uint128 _frac, address _sender)
        external
        onlyPoption
        noReentrant
    {
        _onLiquidIn(_frac, _sender);
    }

    function onLiquidIn(uint128 _frac, address _sender)
        external
        onlyPoption
        noReentrant
    {
        _onLiquidIn(_frac, _sender);
    }

    function liquidOut(uint128 _share) public noReentrant {
        uint128 share = liqPoolShare[msg.sender];
        require(share >= _share, "NES");
        uint128 priceDivisor = 0;
        uint128[STRIKE_NUM] memory lqRemove;
        uint128 frac = _share.div(liqPoolShareAll);
        uint128[STRIKE_NUM] memory weight = getWeight();
        for (uint256 i = 0; i < STRIKE_NUM; i++) {
            lqRemove[i] = frac.mul(liqPool[i]);
            priceDivisor += weight[i].div(liqPool[i]);
        }
        uint128 value = frac.div(priceDivisor);
        if (value > valueNoFee[msg.sender]) {
            uint128 optShare = _share.mul(
                (value - valueNoFee[msg.sender]).mul(l2FeeRate).div(value)
            );
            uint128 optFrac = optShare.div(liqPoolShareAll);
            for (uint256 i = 0; i < STRIKE_NUM; i++) {
                lqRemove[i] = lqRemove[i] - optFrac.mul(liqPool[i]);
                liqPool[i] -= lqRemove[i];
            }
            liqPoolShare[owner] += optShare;
            liqPoolShare[msg.sender] -= _share;
            liqPoolShareAll -= _share - optShare;
            valueNoFee[msg.sender] = 0;
            emit Transfer(msg.sender, address(0), _share - optShare);
            emit Burn(msg.sender, _share - optShare, liqPoolShareAll, liqPool);
        } else {
            liqPoolShare[msg.sender] -= _share;
            liqPoolShareAll -= _share;
            valueNoFee[msg.sender] -= value;
            for (uint256 i = 0; i < STRIKE_NUM; i++) {
                liqPool[i] -= lqRemove[i];
            }
            emit Transfer(msg.sender, address(0), _share);
            emit Burn(msg.sender, _share, liqPoolShareAll, liqPool);
        }
        poption.transfer(msg.sender, lqRemove);
    }

    function destroy() public onlyOwner noReentrant {
        require(block.timestamp > destroyTime, "NDT");
        uint128[STRIKE_NUM] memory rest = poption.balanceOfAll(address(this));
        poption.transfer(owner, rest);
        selfdestruct(payable(owner));
    }

    // IERC20 implement
    function totalSupply() public view returns (uint256) {
        return uint256(liqPoolShareAll);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return uint256(liqPoolShare[_owner]);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "F 0 Addr");
        require(to != address(0), "T 0 Addr");

        uint128 fromShare = liqPoolShare[from];
        require(fromShare >= amount, "Ex Share");
        unchecked {
            liqPoolShare[from] = fromShare - uint128(amount);
        }
        liqPoolShare[to] += uint128(amount);

        emit Transfer(from, to, amount);
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 currentAllowance = allowances[_from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "No En Al");
            unchecked {
                allowances[_from][msg.sender] = currentAllowance - _value;
                emit Approval(_from, msg.sender, _value);
            }
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        require(_spender != address(0), "A 0 Addr");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _shareOwner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowances[_shareOwner][_spender];
    }
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Test ETC20 class for poption
 * Copyright ©2022 by Poption.org.
 * Author: Poption <[email protected]>
 */

pragma solidity ^0.8.4;

interface IOracle {
    function source() external view returns (address);

    function get() external view returns (uint128);

    function token0Symbol() external view returns (string memory);

    function token1Symbol() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Copyright ©2022 by Poption.
 * Author: Hydrogenbear <[email protected]>
 */

pragma solidity ^0.8.4;

uint256 constant STRIKE_NUM = 16;

// SPDX-License-Identifier: BUSL-1.1
/*
 * Copyright ©2022 by Poption.
 * Author: Hydrogenbear <[email protected]>
 */
pragma solidity ^0.8.4;

import "../StrikeNum.sol";

interface ISwap {
    function toSwap(
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) external;

    function onSwap(
        uint128[STRIKE_NUM] calldata _out,
        uint128[STRIKE_NUM] calldata _in
    ) external;

    function toLiquidIn(uint128 frac, address sender) external;

    function onLiquidIn(uint128 frac, address sender) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}