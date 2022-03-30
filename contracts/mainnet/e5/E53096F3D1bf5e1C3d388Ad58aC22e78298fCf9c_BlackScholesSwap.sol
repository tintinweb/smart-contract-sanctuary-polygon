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
    int128[SLOT_NUM] public lnSlots;
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

    function init() external override onlyOwner noReentrant {
        require(!_isInited, "INITED");
        super._init();
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            lnSlots[i] = slots[i].ln();
        }
        _isInited = true;
    }

    function getWeight()
        internal
        view
        override
        returns (uint128[SLOT_NUM] memory weight)
    {
        if (block.timestamp < settleTime) {
            uint128 price = IOracle(oracle).get();
            int128 std = int128(
                volatility.mul(
                    (uint128((settleTime - block.timestamp) << 64)).sqrt()
                )
            );
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
            int128 x = lnSlots[0].div(std);
            uint128 a0 = Math64x64.normCdf(x - bias0);
            uint128 t0 = Math64x64.normCdf(x - bias1).mul(scale);
            weight[0] = a0;
            for (i = 1; i < SLOT_NUM; i++) {
                x = lnSlots[i].div(std);
                uint128 a1 = Math64x64.normCdf(x - bias0);
                uint128 t1 = Math64x64.normCdf(x - bias1).mul(scale);
                uint128 gap = slots[i] - slots[i - 1];
                uint128 aa = (a1 - a0).mul(slots[i]) + t0;
                if (aa < t1) {
                    weight[i - 1] += 0;
                } else {
                    weight[i - 1] += (aa - t1).div(gap);
                }
                aa = (a1 - a0).mul(slots[i - 1]) + t0;
                if (aa > t1) {
                    weight[i] = 0;
                } else {
                    weight[i] = (t1 - aa).div(gap);
                }
                a0 = a1;
                t0 = t1;
            }
            weight[SLOT_NUM - 1] += 0x10000000000000000 - a0;
        } else {
            weight = getWeightAfterSettle();
        }
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
        require(x >= 0);
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
        require(rx > 0);
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

    function invSqrt(uint128 x) internal pure returns (uint128 r) {
        require(x >= 1);
        unchecked {
            int128 msbx = msb(x);
            assembly {
                let rx := div(
                    0x1000000000000000000000000000000000000000000000000,
                    x
                )
                r := shr(sub(96, sar(1, msbx)), rx)
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
                r := shr(1, add(div(rx, r), r))
            }
        }
    }

    function sqrt(uint128 x) internal pure returns (uint128 r) {
        require(x >= 1);
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
        require(x < 0x2bab13e5fca20ef146);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IOracle.sol";
import "./interface/ISwap.sol";
import "./Math.sol";

contract Poption {
    using Math64x64 for uint128;
    uint256 constant SLOT_NUM = 16;

    uint128[SLOT_NUM] public slots;
    mapping(address => uint128[SLOT_NUM]) public options;
    mapping(bytes32 => bool) public usedHash;

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

    event Transfer(address indexed sender, address indexed recipient);

    constructor(
        address _token,
        address _oracle,
        uint256 _settleTime,
        uint128[SLOT_NUM] memory slots_
    ) {
        token = _token;
        oracle = IOracle(_oracle);
        settleTime = _settleTime;
        slots = slots_;
    }

    function getState()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint128[SLOT_NUM] memory
        )
    {
        return (token, address(oracle), settleTime, slots);
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
                if (price <= slots[0]) {
                    settleIdx = 1;
                    settleWeight0 = 1;
                    settleWeight1 = 0;
                } else if (price >= slots[SLOT_NUM - 1]) {
                    settleIdx = uint8(SLOT_NUM - 1);
                    settleWeight0 = 0;
                    settleWeight1 = 1;
                } else {
                    uint8 h = uint8(SLOT_NUM - 1);
                    uint8 l = 0;
                    settleIdx = (h + l) >> 1;
                    while (h > l) {
                        if (slots[settleIdx] >= price) {
                            h = settleIdx;
                        } else {
                            l = settleIdx + 1;
                        }
                        settleIdx = (h + l) >> 1;
                    }
                    uint128 delta = slots[settleIdx] - slots[settleIdx - 1];
                    settleWeight0 = (slots[settleIdx] - price).div(delta);
                    settleWeight1 = (price - slots[settleIdx - 1]).div(delta);
                }
            }
            require(isSettled, "NSET");
        }
    }

    function balanceOf(address addr)
        external
        view
        returns (uint128[SLOT_NUM] memory)
    {
        return options[addr];
    }

    function _safeTransferFrom(
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

    function _safeTransfer(
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
        uint128[SLOT_NUM] memory _option
    ) private {
        unchecked {
            for (uint256 i = 0; i < SLOT_NUM; i++) {
                require(_option[i] <= options[_from][i], "NEO");
                options[_to][i] += _option[i];
                options[_from][i] -= _option[i];
            }
            emit Transfer(_from, _to);
        }
    }

    function transfer(address _recipient, uint128[SLOT_NUM] calldata _option)
        external
        noReentrant
    {
        _transfer(msg.sender, _recipient, _option);
    }

    function mint(uint128 _assert) public noReentrant {
        _safeTransferFrom(token, msg.sender, address(this), _assert);
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            options[msg.sender][i] += _assert;
        }
        emit Transfer(address(0), msg.sender);
    }

    function burn(uint128 _assert) public noReentrant {
        unchecked {
            for (uint256 i = 0; i < SLOT_NUM; i++) {
                require(_assert <= options[msg.sender][i], "NEO");
                options[msg.sender][i] -= _assert;
            }
        }
        _safeTransfer(token, address(msg.sender), uint256(_assert));
        emit Transfer(msg.sender, address(0));
    }

    function outSwap(
        address marketMaker,
        uint128[SLOT_NUM] calldata _out,
        uint128[SLOT_NUM] calldata _in,
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
        uint128[SLOT_NUM] calldata _out,
        uint128[SLOT_NUM] calldata _in
    ) public noReentrant {
        ISwap(marketMaker).toSwap(_out, _in);
        _transfer(marketMaker, msg.sender, _out);
        _transfer(msg.sender, marketMaker, _in);
    }

    function liquidIn(address marketMaker, uint128 frac) external noReentrant {
        uint128[SLOT_NUM] memory option;
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            option[i] = options[marketMaker][i].mul(frac);
        }
        _transfer(msg.sender, marketMaker, option);
        ISwap(marketMaker).toLiquidIn(frac, msg.sender);
    }

    function exercise() external {
        exerciseTail(0);
    }

    function exerciseTail(uint128 tail) public noReentrant {
        settle();
        uint128 _assert = options[msg.sender][settleIdx - 1].mul(
            settleWeight0
        ) +
            options[msg.sender][settleIdx].mul(settleWeight1) -
            tail;
        options[msg.sender][settleIdx - 1] = 0;
        options[msg.sender][settleIdx] = 0;
        _safeTransfer(token, address(msg.sender), _assert);
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
import "./interface/IOracle.sol";

contract BaseCFMMSwap {
    using Math64x64 for uint128;
    using Math64x64 for int128;
    uint256 constant SLOT_NUM = 16;

    uint128[SLOT_NUM] public slots;
    uint128[SLOT_NUM] public liqPool;
    mapping(address => uint128) public liqPoolShare;
    uint128 public liqPoolShareAll;
    mapping(address => uint128) public valueNoFee;

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
        (token, oracle, _settleTime, slots) = Poption(_poption).getState();
        require(_closeTime < _settleTime && _settleTime < _destroyTime, "TCK");
        closeTime = _closeTime;
        settleTime = _settleTime;
        destroyTime = _destroyTime;
        feeRate = _feeRate;
        l2FeeRate = _l2FeeRate;
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

    modifier marketOpen() {
        require(_isInited && (block.timestamp > closeTime), "MC");
        _;
    }

    function getWeight()
        internal
        view
        virtual
        returns (uint128[SLOT_NUM] memory weight)
    {
        if (block.timestamp < settleTime) {
            weight = [
                uint128(0x1000000000000000),
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000,
                0x1000000000000000
            ];
        } else {
            weight = getWeightAfterSettle();
        }
    }

    function _init() internal {
        uint128[SLOT_NUM] memory _option = poption.balanceOf(address(this));
        uint128 share;
        for (uint256 i; i < SLOT_NUM; i++) {
            require(_option[i] > 100, "TL");
            liqPool[i] = _option[i];
            share += _option[i];
        }
        share = share / uint128(SLOT_NUM);
        liqPoolShare[msg.sender] += share;
        valueNoFee[msg.sender] = 0x7fffffffffffffffffffffffffffffff;
        liqPoolShareAll += share;
    }

    function init() external virtual onlyOwner noReentrant {
        require(!_isInited, "INITED");
        _init();
        _isInited = true;
    }

    function getStatus()
        external
        view
        returns (
            uint128[SLOT_NUM] memory,
            uint128[SLOT_NUM] memory,
            uint128
        )
    {
        return (getWeight(), liqPool, feeRate);
    }

    function tradeFunction(uint128[16] memory liq, uint128[16] memory w)
        internal
        pure
        returns (int128 res)
    {
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            res += liq[i].ln().mul(int128(w[i]));
        }
    }

    function getWeightAfterSettle()
        internal
        view
        returns (uint128[SLOT_NUM] memory weight)
    {
        weight = [uint128(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        uint8 settleIdx;
        uint128 settleWeight0;
        uint128 settleWeight1;
        if (poption.isSettled()) {
            settleIdx = poption.settleIdx();
            settleWeight0 = poption.settleWeight0();
            settleWeight1 = poption.settleWeight1();
        } else {
            uint128 price = IOracle(oracle).get();
            if (price <= slots[0]) {
                settleIdx = 1;
                settleWeight0 = 1;
                settleWeight1 = 0;
            } else if (price >= slots[SLOT_NUM - 1]) {
                settleIdx = uint8(SLOT_NUM - 1);
                settleWeight0 = 0;
                settleWeight1 = 1;
            } else {
                uint8 h = uint8(SLOT_NUM - 1);
                uint8 l = 0;
                settleIdx = (h + l) >> 1;
                while (h > l) {
                    if (slots[settleIdx] >= price) {
                        h = settleIdx;
                    } else {
                        l = settleIdx + 1;
                    }
                    settleIdx = (h + l) >> 1;
                }
                uint128 delta = slots[settleIdx] - slots[settleIdx - 1];
                settleWeight0 = (slots[settleIdx] - price).div(delta);
                settleWeight1 = (price - slots[settleIdx - 1]).div(delta);
            }
        }
        uint128 p0 = settleWeight0.mul(liqPool[settleIdx - 1]);
        uint128 p1 = settleWeight1.mul(liqPool[settleIdx]);
        weight[settleIdx - 1] = p0.div(p0 + p1);
        weight[settleIdx] = p1.div(p0 + p1);
    }

    function _toSwap(
        uint128[SLOT_NUM] calldata _out,
        uint128[SLOT_NUM] calldata _in
    ) internal {
        uint128[SLOT_NUM] memory weight = getWeight();
        int256 const_now = tradeFunction(liqPool, weight);
        uint128[SLOT_NUM] memory lp_to;
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            uint128 outi = _out[i].mul(feeRate);
            require(liqPool[i] > outi, "PLQ");
            lp_to[i] = liqPool[i] + _in[i].div(feeRate) - outi;
        }
        int256 const_to = tradeFunction(lp_to, weight);
        require(const_to >= const_now, "PMC");
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            liqPool[i] = liqPool[i] + _in[i] - _out[i];
        }
    }

    function toSwap(
        uint128[SLOT_NUM] calldata _out,
        uint128[SLOT_NUM] calldata _in
    ) external noReentrant onlyPoption {
        require(block.timestamp < closeTime, "MCT");
        _toSwap(_out, _in);
    }

    function destroy() public onlyOwner noReentrant {
        require(block.timestamp > destroyTime, "NDT");
        uint128[SLOT_NUM] memory rest = poption.balanceOf(address(this));
        poption.transfer(owner, rest);
        selfdestruct(payable(owner));
    }

    function _toLiquidIn(uint128 frac, address msgSender) internal {
        uint128 priceDivisor = 0;
        uint128 shareAdd = frac.mul(liqPoolShareAll);
        liqPoolShareAll += shareAdd;
        liqPoolShare[msgSender] += shareAdd;
        uint128[SLOT_NUM] memory weight = getWeight();
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            priceDivisor += uint128(weight[i]).div(liqPool[i]);
            liqPool[i] += frac.mul(liqPool[i]);
        }
        valueNoFee[msgSender] += frac.div(priceDivisor);
    }

    function toLiquidIn(uint128 frac, address sender)
        external
        onlyPoption
        noReentrant
    {
        _toLiquidIn(frac, sender);
    }

    function liquidOut(uint128 _share) public noReentrant {
        uint128 share = liqPoolShare[msg.sender];
        require(share >= _share, "NES");
        uint128 priceDivisor = 0;
        uint128[SLOT_NUM] memory lqRemove;
        uint128 frac = _share.div(liqPoolShareAll);
        uint128[SLOT_NUM] memory weight = getWeight();
        for (uint256 i = 0; i < SLOT_NUM; i++) {
            lqRemove[i] = frac.mul(liqPool[i]);
            priceDivisor += weight[i].div(liqPool[i]);
        }
        uint128 value = frac.div(priceDivisor);
        if (value > valueNoFee[msg.sender]) {
            uint128 optShare = _share.mul(
                (value - valueNoFee[msg.sender]).mul(l2FeeRate).div(value)
            );
            uint128 optFrac = optShare.div(liqPoolShareAll);
            for (uint256 i = 0; i < SLOT_NUM; i++) {
                lqRemove[i] = lqRemove[i] - optFrac.mul(liqPool[i]);
                liqPool[i] -= lqRemove[i];
            }
            liqPoolShare[owner] += optShare;
            liqPoolShare[msg.sender] -= _share;
            liqPoolShareAll -= _share - optShare;
            valueNoFee[msg.sender] = 0;
        } else {
            liqPoolShare[msg.sender] -= _share;
            liqPoolShareAll -= _share;
            valueNoFee[msg.sender] -= value;
            for (uint256 i = 0; i < SLOT_NUM; i++) {
                liqPool[i] -= lqRemove[i];
            }
        }
        poption.transfer(msg.sender, lqRemove);
    }

    function setFeeRate(uint128 _feeRate) external onlyOwner {
        feeRate = _feeRate;
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

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: BUSL-1.1
/*
 * Copyright ©2022 by Poption.
 * Author: Hydrogenbear <[email protected]>
 */
pragma solidity ^0.8.4;

interface ISwap {
    function toSwap(uint128[16] calldata _out, uint128[16] calldata _in)
        external;

    function toLiquidIn(uint128 frac, address sender) external;
}