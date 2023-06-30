/**
 *Submitted for verification at polygonscan.com on 2023-06-29
*/

pragma solidity ^0.8.17;

contract Verifier {
    function verify(
        uint256[] memory pubInputs,
        bytes memory proof
    ) public view returns (bool) {
        bool success = true;
        bytes32[] memory transcript;
        assembly {
            let
                f_p
            := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            let
                f_q
            := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            function validate_ec_point(x, y) -> valid {
                {
                    let x_lt_p := lt(
                        x,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    let y_lt_p := lt(
                        y,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    valid := and(x_lt_p, y_lt_p)
                }
                {
                    let y_square := mulmod(
                        y,
                        y,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    let x_square := mulmod(
                        x,
                        x,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    let x_cube := mulmod(
                        x_square,
                        x,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    let x_cube_plus_3 := addmod(
                        x_cube,
                        3,
                        0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                    )
                    let is_affine := eq(x_cube_plus_3, y_square)
                    valid := and(valid, is_affine)
                }
            }
            mstore(0xac0, mod(mload(0xa0), f_q))
            mstore(
                0xaa0,
                5373021484055170268144901179801362807418713018587544446805867017084227995190
            )
            {
                let x := mload(0xe0)
                mstore(0xae0, x)
                let y := mload(0x100)
                mstore(0xb00, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x120)
                mstore(0xb20, x)
                let y := mload(0x140)
                mstore(0xb40, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x160)
                mstore(0xb60, x)
                let y := mload(0x180)
                mstore(0xb80, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0xba0, keccak256(0xaa0, 256))
            {
                let hash := mload(0xba0)
                mstore(0xbc0, mod(hash, f_q))
                mstore(0xbe0, hash)
            }
            {
                let x := mload(0x1a0)
                mstore(0xc00, x)
                let y := mload(0x1c0)
                mstore(0xc20, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x1e0)
                mstore(0xc40, x)
                let y := mload(0x200)
                mstore(0xc60, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x220)
                mstore(0xc80, x)
                let y := mload(0x240)
                mstore(0xca0, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x260)
                mstore(0xcc0, x)
                let y := mload(0x280)
                mstore(0xce0, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0xd00, keccak256(0xbe0, 288))
            {
                let hash := mload(0xd00)
                mstore(0xd20, mod(hash, f_q))
                mstore(0xd40, hash)
            }
            mstore8(0xd60, 1)
            mstore(0xd60, keccak256(0xd40, 33))
            {
                let hash := mload(0xd60)
                mstore(0xd80, mod(hash, f_q))
                mstore(0xda0, hash)
            }
            {
                let x := mload(0x2a0)
                mstore(0xdc0, x)
                let y := mload(0x2c0)
                mstore(0xde0, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x2e0)
                mstore(0xe00, x)
                let y := mload(0x300)
                mstore(0xe20, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x320)
                mstore(0xe40, x)
                let y := mload(0x340)
                mstore(0xe60, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x360)
                mstore(0xe80, x)
                let y := mload(0x380)
                mstore(0xea0, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x3a0)
                mstore(0xec0, x)
                let y := mload(0x3c0)
                mstore(0xee0, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0xf00, keccak256(0xda0, 352))
            {
                let hash := mload(0xf00)
                mstore(0xf20, mod(hash, f_q))
                mstore(0xf40, hash)
            }
            {
                let x := mload(0x3e0)
                mstore(0xf60, x)
                let y := mload(0x400)
                mstore(0xf80, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x420)
                mstore(0xfa0, x)
                let y := mload(0x440)
                mstore(0xfc0, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x460)
                mstore(0xfe0, x)
                let y := mload(0x480)
                mstore(0x1000, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x4a0)
                mstore(0x1020, x)
                let y := mload(0x4c0)
                mstore(0x1040, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x1060, keccak256(0xf40, 288))
            {
                let hash := mload(0x1060)
                mstore(0x1080, mod(hash, f_q))
                mstore(0x10a0, hash)
            }
            mstore(0x10c0, mod(mload(0x4e0), f_q))
            mstore(0x10e0, mod(mload(0x500), f_q))
            mstore(0x1100, mod(mload(0x520), f_q))
            mstore(0x1120, mod(mload(0x540), f_q))
            mstore(0x1140, mod(mload(0x560), f_q))
            mstore(0x1160, mod(mload(0x580), f_q))
            mstore(0x1180, mod(mload(0x5a0), f_q))
            mstore(0x11a0, mod(mload(0x5c0), f_q))
            mstore(0x11c0, mod(mload(0x5e0), f_q))
            mstore(0x11e0, mod(mload(0x600), f_q))
            mstore(0x1200, mod(mload(0x620), f_q))
            mstore(0x1220, mod(mload(0x640), f_q))
            mstore(0x1240, mod(mload(0x660), f_q))
            mstore(0x1260, mod(mload(0x680), f_q))
            mstore(0x1280, mod(mload(0x6a0), f_q))
            mstore(0x12a0, mod(mload(0x6c0), f_q))
            mstore(0x12c0, mod(mload(0x6e0), f_q))
            mstore(0x12e0, mod(mload(0x700), f_q))
            mstore(0x1300, mod(mload(0x720), f_q))
            mstore(0x1320, mod(mload(0x740), f_q))
            mstore(0x1340, mod(mload(0x760), f_q))
            mstore(0x1360, mod(mload(0x780), f_q))
            mstore(0x1380, mod(mload(0x7a0), f_q))
            mstore(0x13a0, mod(mload(0x7c0), f_q))
            mstore(0x13c0, mod(mload(0x7e0), f_q))
            mstore(0x13e0, mod(mload(0x800), f_q))
            mstore(0x1400, mod(mload(0x820), f_q))
            mstore(0x1420, mod(mload(0x840), f_q))
            mstore(0x1440, mod(mload(0x860), f_q))
            mstore(0x1460, mod(mload(0x880), f_q))
            mstore(0x1480, mod(mload(0x8a0), f_q))
            mstore(0x14a0, mod(mload(0x8c0), f_q))
            mstore(0x14c0, mod(mload(0x8e0), f_q))
            mstore(0x14e0, mod(mload(0x900), f_q))
            mstore(0x1500, mod(mload(0x920), f_q))
            mstore(0x1520, mod(mload(0x940), f_q))
            mstore(0x1540, mod(mload(0x960), f_q))
            mstore(0x1560, mod(mload(0x980), f_q))
            mstore(0x1580, keccak256(0x10a0, 1248))
            {
                let hash := mload(0x1580)
                mstore(0x15a0, mod(hash, f_q))
                mstore(0x15c0, hash)
            }
            {
                let x := mload(0x9a0)
                mstore(0x15e0, x)
                let y := mload(0x9c0)
                mstore(0x1600, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0x9e0)
                mstore(0x1620, x)
                let y := mload(0xa00)
                mstore(0x1640, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0xa20)
                mstore(0x1660, x)
                let y := mload(0xa40)
                mstore(0x1680, y)
                success := and(validate_ec_point(x, y), success)
            }
            {
                let x := mload(0xa60)
                mstore(0x16a0, x)
                let y := mload(0xa80)
                mstore(0x16c0, y)
                success := and(validate_ec_point(x, y), success)
            }
            mstore(0x16e0, keccak256(0x15c0, 288))
            {
                let hash := mload(0x16e0)
                mstore(0x1700, mod(hash, f_q))
                mstore(0x1720, hash)
            }
            mstore(0x1740, mulmod(mload(0x1080), mload(0x1080), f_q))
            mstore(0x1760, mulmod(mload(0x1740), mload(0x1740), f_q))
            mstore(0x1780, mulmod(mload(0x1760), mload(0x1760), f_q))
            mstore(0x17a0, mulmod(mload(0x1780), mload(0x1780), f_q))
            mstore(0x17c0, mulmod(mload(0x17a0), mload(0x17a0), f_q))
            mstore(0x17e0, mulmod(mload(0x17c0), mload(0x17c0), f_q))
            mstore(0x1800, mulmod(mload(0x17e0), mload(0x17e0), f_q))
            mstore(0x1820, mulmod(mload(0x1800), mload(0x1800), f_q))
            mstore(0x1840, mulmod(mload(0x1820), mload(0x1820), f_q))
            mstore(0x1860, mulmod(mload(0x1840), mload(0x1840), f_q))
            mstore(0x1880, mulmod(mload(0x1860), mload(0x1860), f_q))
            mstore(0x18a0, mulmod(mload(0x1880), mload(0x1880), f_q))
            mstore(0x18c0, mulmod(mload(0x18a0), mload(0x18a0), f_q))
            mstore(0x18e0, mulmod(mload(0x18c0), mload(0x18c0), f_q))
            mstore(0x1900, mulmod(mload(0x18e0), mload(0x18e0), f_q))
            mstore(0x1920, mulmod(mload(0x1900), mload(0x1900), f_q))
            mstore(0x1940, mulmod(mload(0x1920), mload(0x1920), f_q))
            mstore(0x1960, mulmod(mload(0x1940), mload(0x1940), f_q))
            mstore(0x1980, mulmod(mload(0x1960), mload(0x1960), f_q))
            mstore(
                0x19a0,
                addmod(
                    mload(0x1980),
                    21888242871839275222246405745257275088548364400416034343698204186575808495616,
                    f_q
                )
            )
            mstore(
                0x19c0,
                mulmod(
                    mload(0x19a0),
                    21888201123329158951656153352668191879939568188478319927128792530760328118785,
                    f_q
                )
            )
            mstore(
                0x19e0,
                mulmod(
                    mload(0x19c0),
                    15837174511167031493871940795515473313759957271874477857633393696392913897559,
                    f_q
                )
            )
            mstore(
                0x1a00,
                addmod(
                    mload(0x1080),
                    6051068360672243728374464949741801774788407128541556486064810490182894598058,
                    f_q
                )
            )
            mstore(
                0x1a20,
                mulmod(
                    mload(0x19c0),
                    1769632609887742868080915468068339302011836563132608883078842147442873613232,
                    f_q
                )
            )
            mstore(
                0x1a40,
                addmod(
                    mload(0x1080),
                    20118610261951532354165490277188935786536527837283425460619362039132934882385,
                    f_q
                )
            )
            mstore(
                0x1a60,
                mulmod(
                    mload(0x19c0),
                    11402394834529375719535454173347509224290498423785625657829583372803806900475,
                    f_q
                )
            )
            mstore(
                0x1a80,
                addmod(
                    mload(0x1080),
                    10485848037309899502710951571909765864257865976630408685868620813772001595142,
                    f_q
                )
            )
            mstore(
                0x1aa0,
                mulmod(
                    mload(0x19c0),
                    13315224328250071823986980334210714047804323884995968263773489477577155309695,
                    f_q
                )
            )
            mstore(
                0x1ac0,
                addmod(
                    mload(0x1080),
                    8573018543589203398259425411046561040744040515420066079924714708998653185922,
                    f_q
                )
            )
            mstore(
                0x1ae0,
                mulmod(
                    mload(0x19c0),
                    6363119021782681274480715230122258277189830284152385293217720612674619714422,
                    f_q
                )
            )
            mstore(
                0x1b00,
                addmod(
                    mload(0x1080),
                    15525123850056593947765690515135016811358534116263649050480483573901188781195,
                    f_q
                )
            )
            mstore(
                0x1b20,
                mulmod(
                    mload(0x19c0),
                    14686510910986211321976396297238126901237973400949744736326777596334651355305,
                    f_q
                )
            )
            mstore(
                0x1b40,
                addmod(
                    mload(0x1080),
                    7201731960853063900270009448019148187310390999466289607371426590241157140312,
                    f_q
                )
            )
            mstore(0x1b60, mulmod(mload(0x19c0), 1, f_q))
            mstore(
                0x1b80,
                addmod(
                    mload(0x1080),
                    21888242871839275222246405745257275088548364400416034343698204186575808495616,
                    f_q
                )
            )
            {
                let prod := mload(0x1a00)
                prod := mulmod(mload(0x1a40), prod, f_q)
                mstore(0x1ba0, prod)
                prod := mulmod(mload(0x1a80), prod, f_q)
                mstore(0x1bc0, prod)
                prod := mulmod(mload(0x1ac0), prod, f_q)
                mstore(0x1be0, prod)
                prod := mulmod(mload(0x1b00), prod, f_q)
                mstore(0x1c00, prod)
                prod := mulmod(mload(0x1b40), prod, f_q)
                mstore(0x1c20, prod)
                prod := mulmod(mload(0x1b80), prod, f_q)
                mstore(0x1c40, prod)
                prod := mulmod(mload(0x19a0), prod, f_q)
                mstore(0x1c60, prod)
            }
            mstore(0x1ca0, 32)
            mstore(0x1cc0, 32)
            mstore(0x1ce0, 32)
            mstore(0x1d00, mload(0x1c60))
            mstore(
                0x1d20,
                21888242871839275222246405745257275088548364400416034343698204186575808495615
            )
            mstore(
                0x1d40,
                21888242871839275222246405745257275088548364400416034343698204186575808495617
            )
            success := and(
                eq(staticcall(gas(), 0x5, 0x1ca0, 0xc0, 0x1c80, 0x20), 1),
                success
            )
            {
                let inv := mload(0x1c80)
                let v
                v := mload(0x19a0)
                mstore(0x19a0, mulmod(mload(0x1c40), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1b80)
                mstore(0x1b80, mulmod(mload(0x1c20), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1b40)
                mstore(0x1b40, mulmod(mload(0x1c00), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1b00)
                mstore(0x1b00, mulmod(mload(0x1be0), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1ac0)
                mstore(0x1ac0, mulmod(mload(0x1bc0), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1a80)
                mstore(0x1a80, mulmod(mload(0x1ba0), inv, f_q))
                inv := mulmod(v, inv, f_q)
                v := mload(0x1a40)
                mstore(0x1a40, mulmod(mload(0x1a00), inv, f_q))
                inv := mulmod(v, inv, f_q)
                mstore(0x1a00, inv)
            }
            mstore(0x1d60, mulmod(mload(0x19e0), mload(0x1a00), f_q))
            mstore(0x1d80, mulmod(mload(0x1a20), mload(0x1a40), f_q))
            mstore(0x1da0, mulmod(mload(0x1a60), mload(0x1a80), f_q))
            mstore(0x1dc0, mulmod(mload(0x1aa0), mload(0x1ac0), f_q))
            mstore(0x1de0, mulmod(mload(0x1ae0), mload(0x1b00), f_q))
            mstore(0x1e00, mulmod(mload(0x1b20), mload(0x1b40), f_q))
            mstore(0x1e20, mulmod(mload(0x1b60), mload(0x1b80), f_q))
            {
                let result := mulmod(mload(0x1e20), mload(0xac0), f_q)
                mstore(0x1e40, result)
            }
            mstore(0x1e60, addmod(1, sub(f_q, mload(0x1240)), f_q))
            mstore(0x1e80, mulmod(mload(0x1e60), mload(0x1240), f_q))
            mstore(0x1ea0, addmod(2, sub(f_q, mload(0x1240)), f_q))
            mstore(0x1ec0, mulmod(mload(0x1ea0), mload(0x1e80), f_q))
            mstore(0x1ee0, mulmod(mload(0x10e0), mload(0x10c0), f_q))
            mstore(0x1f00, addmod(mload(0x1ee0), mload(0x1120), f_q))
            mstore(0x1f20, addmod(mload(0x1100), sub(f_q, mload(0x1f00)), f_q))
            mstore(0x1f40, mulmod(mload(0x1f20), mload(0x1ec0), f_q))
            mstore(0x1f60, mulmod(mload(0xf20), mload(0x1f40), f_q))
            mstore(0x1f80, addmod(1, sub(f_q, mload(0x1280)), f_q))
            mstore(0x1fa0, mulmod(mload(0x1f80), mload(0x1280), f_q))
            mstore(0x1fc0, addmod(2, sub(f_q, mload(0x1280)), f_q))
            mstore(0x1fe0, mulmod(mload(0x1fc0), mload(0x1fa0), f_q))
            mstore(0x2000, addmod(mload(0x1100), sub(f_q, mload(0x10e0)), f_q))
            mstore(0x2020, mulmod(mload(0x2000), mload(0x1fe0), f_q))
            mstore(0x2040, addmod(mload(0x1f60), mload(0x2020), f_q))
            mstore(0x2060, mulmod(mload(0xf20), mload(0x2040), f_q))
            mstore(0x2080, mulmod(mload(0x1ea0), mload(0x1240), f_q))
            mstore(0x20a0, addmod(3, sub(f_q, mload(0x1240)), f_q))
            mstore(0x20c0, mulmod(mload(0x20a0), mload(0x2080), f_q))
            mstore(0x20e0, addmod(mload(0x10c0), mload(0x10e0), f_q))
            mstore(0x2100, addmod(mload(0x1100), sub(f_q, mload(0x20e0)), f_q))
            mstore(0x2120, mulmod(mload(0x2100), mload(0x20c0), f_q))
            mstore(0x2140, addmod(mload(0x2060), mload(0x2120), f_q))
            mstore(0x2160, mulmod(mload(0xf20), mload(0x2140), f_q))
            mstore(0x2180, addmod(1, sub(f_q, mload(0x1260)), f_q))
            mstore(0x21a0, mulmod(mload(0x2180), mload(0x1260), f_q))
            mstore(0x21c0, addmod(2, sub(f_q, mload(0x1260)), f_q))
            mstore(0x21e0, mulmod(mload(0x21c0), mload(0x21a0), f_q))
            mstore(0x2200, addmod(mload(0x1100), sub(f_q, mload(0x1ee0)), f_q))
            mstore(0x2220, mulmod(mload(0x2200), mload(0x21e0), f_q))
            mstore(0x2240, addmod(mload(0x2160), mload(0x2220), f_q))
            mstore(0x2260, mulmod(mload(0xf20), mload(0x2240), f_q))
            mstore(0x2280, mulmod(mload(0x20a0), mload(0x1e80), f_q))
            mstore(0x22a0, addmod(mload(0x10c0), sub(f_q, mload(0x10e0)), f_q))
            mstore(0x22c0, addmod(mload(0x1100), sub(f_q, mload(0x22a0)), f_q))
            mstore(0x22e0, mulmod(mload(0x22c0), mload(0x2280), f_q))
            mstore(0x2300, addmod(mload(0x2260), mload(0x22e0), f_q))
            mstore(0x2320, mulmod(mload(0xf20), mload(0x2300), f_q))
            mstore(0x2340, mulmod(mload(0x21c0), mload(0x1260), f_q))
            mstore(0x2360, addmod(3, sub(f_q, mload(0x1260)), f_q))
            mstore(0x2380, mulmod(mload(0x2360), mload(0x2340), f_q))
            mstore(0x23a0, addmod(mload(0x10e0), mload(0x1120), f_q))
            mstore(0x23c0, addmod(mload(0x1100), sub(f_q, mload(0x23a0)), f_q))
            mstore(0x23e0, mulmod(mload(0x23c0), mload(0x2380), f_q))
            mstore(0x2400, addmod(mload(0x2320), mload(0x23e0), f_q))
            mstore(0x2420, mulmod(mload(0xf20), mload(0x2400), f_q))
            mstore(0x2440, mulmod(mload(0x2360), mload(0x21a0), f_q))
            mstore(
                0x2460,
                addmod(mload(0x1100), sub(f_q, sub(f_q, mload(0x10e0))), f_q)
            )
            mstore(0x2480, mulmod(mload(0x2460), mload(0x2440), f_q))
            mstore(0x24a0, addmod(mload(0x2420), mload(0x2480), f_q))
            mstore(0x24c0, mulmod(mload(0xf20), mload(0x24a0), f_q))
            mstore(0x24e0, mulmod(mload(0x1fc0), mload(0x1280), f_q))
            mstore(0x2500, addmod(3, sub(f_q, mload(0x1280)), f_q))
            mstore(0x2520, mulmod(mload(0x2500), mload(0x24e0), f_q))
            mstore(0x2540, addmod(mload(0x10e0), sub(f_q, mload(0x1100)), f_q))
            mstore(0x2560, mulmod(mload(0x2540), mload(0x2520), f_q))
            mstore(0x2580, addmod(mload(0x24c0), mload(0x2560), f_q))
            mstore(0x25a0, mulmod(mload(0xf20), mload(0x2580), f_q))
            mstore(0x25c0, mulmod(mload(0x2500), mload(0x1fa0), f_q))
            mstore(0x25e0, mulmod(mload(0x10e0), mload(0x25c0), f_q))
            mstore(0x2600, addmod(mload(0x25a0), mload(0x25e0), f_q))
            mstore(0x2620, mulmod(mload(0xf20), mload(0x2600), f_q))
            mstore(
                0x2640,
                addmod(
                    mload(0x10e0),
                    21888242871839275222246405745257275088548364400416034343698204186575808495616,
                    f_q
                )
            )
            mstore(0x2660, mulmod(mload(0x2640), mload(0x10e0), f_q))
            mstore(0x2680, mulmod(mload(0x2660), mload(0x12a0), f_q))
            mstore(0x26a0, addmod(mload(0x2620), mload(0x2680), f_q))
            mstore(0x26c0, mulmod(mload(0xf20), mload(0x26a0), f_q))
            mstore(0x26e0, addmod(1, sub(f_q, mload(0x13a0)), f_q))
            mstore(0x2700, mulmod(mload(0x26e0), mload(0x1e20), f_q))
            mstore(0x2720, addmod(mload(0x26c0), mload(0x2700), f_q))
            mstore(0x2740, mulmod(mload(0xf20), mload(0x2720), f_q))
            mstore(0x2760, mulmod(mload(0x1400), mload(0x1400), f_q))
            mstore(0x2780, addmod(mload(0x2760), sub(f_q, mload(0x1400)), f_q))
            mstore(0x27a0, mulmod(mload(0x2780), mload(0x1d60), f_q))
            mstore(0x27c0, addmod(mload(0x2740), mload(0x27a0), f_q))
            mstore(0x27e0, mulmod(mload(0xf20), mload(0x27c0), f_q))
            mstore(0x2800, addmod(mload(0x1400), sub(f_q, mload(0x13e0)), f_q))
            mstore(0x2820, mulmod(mload(0x2800), mload(0x1e20), f_q))
            mstore(0x2840, addmod(mload(0x27e0), mload(0x2820), f_q))
            mstore(0x2860, mulmod(mload(0xf20), mload(0x2840), f_q))
            mstore(0x2880, addmod(1, sub(f_q, mload(0x1d60)), f_q))
            mstore(0x28a0, addmod(mload(0x1d80), mload(0x1da0), f_q))
            mstore(0x28c0, addmod(mload(0x28a0), mload(0x1dc0), f_q))
            mstore(0x28e0, addmod(mload(0x28c0), mload(0x1de0), f_q))
            mstore(0x2900, addmod(mload(0x28e0), mload(0x1e00), f_q))
            mstore(0x2920, addmod(mload(0x2880), sub(f_q, mload(0x2900)), f_q))
            mstore(0x2940, mulmod(mload(0x12e0), mload(0xd20), f_q))
            mstore(0x2960, addmod(mload(0x10c0), mload(0x2940), f_q))
            mstore(0x2980, addmod(mload(0x2960), mload(0xd80), f_q))
            mstore(0x29a0, mulmod(mload(0x1300), mload(0xd20), f_q))
            mstore(0x29c0, addmod(mload(0x10e0), mload(0x29a0), f_q))
            mstore(0x29e0, addmod(mload(0x29c0), mload(0xd80), f_q))
            mstore(0x2a00, mulmod(mload(0x29e0), mload(0x2980), f_q))
            mstore(0x2a20, mulmod(mload(0x1320), mload(0xd20), f_q))
            mstore(0x2a40, addmod(mload(0x1100), mload(0x2a20), f_q))
            mstore(0x2a60, addmod(mload(0x2a40), mload(0xd80), f_q))
            mstore(0x2a80, mulmod(mload(0x2a60), mload(0x2a00), f_q))
            mstore(0x2aa0, mulmod(mload(0x2a80), mload(0x13c0), f_q))
            mstore(0x2ac0, mulmod(1, mload(0xd20), f_q))
            mstore(0x2ae0, mulmod(mload(0x1080), mload(0x2ac0), f_q))
            mstore(0x2b00, addmod(mload(0x10c0), mload(0x2ae0), f_q))
            mstore(0x2b20, addmod(mload(0x2b00), mload(0xd80), f_q))
            mstore(
                0x2b40,
                mulmod(
                    4131629893567559867359510883348571134090853742863529169391034518566172092834,
                    mload(0xd20),
                    f_q
                )
            )
            mstore(0x2b60, mulmod(mload(0x1080), mload(0x2b40), f_q))
            mstore(0x2b80, addmod(mload(0x10e0), mload(0x2b60), f_q))
            mstore(0x2ba0, addmod(mload(0x2b80), mload(0xd80), f_q))
            mstore(0x2bc0, mulmod(mload(0x2ba0), mload(0x2b20), f_q))
            mstore(
                0x2be0,
                mulmod(
                    8910878055287538404433155982483128285667088683464058436815641868457422632747,
                    mload(0xd20),
                    f_q
                )
            )
            mstore(0x2c00, mulmod(mload(0x1080), mload(0x2be0), f_q))
            mstore(0x2c20, addmod(mload(0x1100), mload(0x2c00), f_q))
            mstore(0x2c40, addmod(mload(0x2c20), mload(0xd80), f_q))
            mstore(0x2c60, mulmod(mload(0x2c40), mload(0x2bc0), f_q))
            mstore(0x2c80, mulmod(mload(0x2c60), mload(0x13a0), f_q))
            mstore(0x2ca0, addmod(mload(0x2aa0), sub(f_q, mload(0x2c80)), f_q))
            mstore(0x2cc0, mulmod(mload(0x2ca0), mload(0x2920), f_q))
            mstore(0x2ce0, addmod(mload(0x2860), mload(0x2cc0), f_q))
            mstore(0x2d00, mulmod(mload(0xf20), mload(0x2ce0), f_q))
            mstore(0x2d20, mulmod(mload(0x1340), mload(0xd20), f_q))
            mstore(0x2d40, addmod(mload(0x1140), mload(0x2d20), f_q))
            mstore(0x2d60, addmod(mload(0x2d40), mload(0xd80), f_q))
            mstore(0x2d80, mulmod(mload(0x1360), mload(0xd20), f_q))
            mstore(0x2da0, addmod(mload(0x1e40), mload(0x2d80), f_q))
            mstore(0x2dc0, addmod(mload(0x2da0), mload(0xd80), f_q))
            mstore(0x2de0, mulmod(mload(0x2dc0), mload(0x2d60), f_q))
            mstore(0x2e00, mulmod(mload(0x1380), mload(0xd20), f_q))
            mstore(0x2e20, addmod(mload(0x1160), mload(0x2e00), f_q))
            mstore(0x2e40, addmod(mload(0x2e20), mload(0xd80), f_q))
            mstore(0x2e60, mulmod(mload(0x2e40), mload(0x2de0), f_q))
            mstore(0x2e80, mulmod(mload(0x2e60), mload(0x1420), f_q))
            mstore(
                0x2ea0,
                mulmod(
                    11166246659983828508719468090013646171463329086121580628794302409516816350802,
                    mload(0xd20),
                    f_q
                )
            )
            mstore(0x2ec0, mulmod(mload(0x1080), mload(0x2ea0), f_q))
            mstore(0x2ee0, addmod(mload(0x1140), mload(0x2ec0), f_q))
            mstore(0x2f00, addmod(mload(0x2ee0), mload(0xd80), f_q))
            mstore(
                0x2f20,
                mulmod(
                    284840088355319032285349970403338060113257071685626700086398481893096618818,
                    mload(0xd20),
                    f_q
                )
            )
            mstore(0x2f40, mulmod(mload(0x1080), mload(0x2f20), f_q))
            mstore(0x2f60, addmod(mload(0x1e40), mload(0x2f40), f_q))
            mstore(0x2f80, addmod(mload(0x2f60), mload(0xd80), f_q))
            mstore(0x2fa0, mulmod(mload(0x2f80), mload(0x2f00), f_q))
            mstore(
                0x2fc0,
                mulmod(
                    21134065618345176623193549882539580312263652408302468683943992798037078993309,
                    mload(0xd20),
                    f_q
                )
            )
            mstore(0x2fe0, mulmod(mload(0x1080), mload(0x2fc0), f_q))
            mstore(0x3000, addmod(mload(0x1160), mload(0x2fe0), f_q))
            mstore(0x3020, addmod(mload(0x3000), mload(0xd80), f_q))
            mstore(0x3040, mulmod(mload(0x3020), mload(0x2fa0), f_q))
            mstore(0x3060, mulmod(mload(0x3040), mload(0x1400), f_q))
            mstore(0x3080, addmod(mload(0x2e80), sub(f_q, mload(0x3060)), f_q))
            mstore(0x30a0, mulmod(mload(0x3080), mload(0x2920), f_q))
            mstore(0x30c0, addmod(mload(0x2d00), mload(0x30a0), f_q))
            mstore(0x30e0, mulmod(mload(0xf20), mload(0x30c0), f_q))
            mstore(0x3100, addmod(1, sub(f_q, mload(0x1440)), f_q))
            mstore(0x3120, mulmod(mload(0x3100), mload(0x1e20), f_q))
            mstore(0x3140, addmod(mload(0x30e0), mload(0x3120), f_q))
            mstore(0x3160, mulmod(mload(0xf20), mload(0x3140), f_q))
            mstore(0x3180, mulmod(mload(0x1440), mload(0x1440), f_q))
            mstore(0x31a0, addmod(mload(0x3180), sub(f_q, mload(0x1440)), f_q))
            mstore(0x31c0, mulmod(mload(0x31a0), mload(0x1d60), f_q))
            mstore(0x31e0, addmod(mload(0x3160), mload(0x31c0), f_q))
            mstore(0x3200, mulmod(mload(0xf20), mload(0x31e0), f_q))
            mstore(0x3220, addmod(mload(0x1480), mload(0xd20), f_q))
            mstore(0x3240, mulmod(mload(0x3220), mload(0x1460), f_q))
            mstore(0x3260, addmod(mload(0x14c0), mload(0xd80), f_q))
            mstore(0x3280, mulmod(mload(0x3260), mload(0x3240), f_q))
            mstore(0x32a0, mulmod(mload(0x10c0), mload(0x1200), f_q))
            mstore(0x32c0, addmod(1, sub(f_q, mload(0x1200)), f_q))
            mstore(0x32e0, mulmod(mload(0x32c0), 0, f_q))
            mstore(0x3300, addmod(mload(0x32a0), mload(0x32e0), f_q))
            mstore(0x3320, mulmod(mload(0xbc0), mload(0x3300), f_q))
            mstore(0x3340, mulmod(mload(0x10e0), mload(0x1200), f_q))
            mstore(0x3360, addmod(mload(0x3340), mload(0x32e0), f_q))
            mstore(0x3380, addmod(mload(0x3320), mload(0x3360), f_q))
            mstore(0x33a0, addmod(mload(0x3380), mload(0xd20), f_q))
            mstore(0x33c0, mulmod(mload(0x33a0), mload(0x1440), f_q))
            mstore(0x33e0, mulmod(mload(0xbc0), mload(0x1180), f_q))
            mstore(0x3400, addmod(mload(0x33e0), mload(0x11a0), f_q))
            mstore(0x3420, addmod(mload(0x3400), mload(0xd80), f_q))
            mstore(0x3440, mulmod(mload(0x3420), mload(0x33c0), f_q))
            mstore(0x3460, addmod(mload(0x3280), sub(f_q, mload(0x3440)), f_q))
            mstore(0x3480, mulmod(mload(0x3460), mload(0x2920), f_q))
            mstore(0x34a0, addmod(mload(0x3200), mload(0x3480), f_q))
            mstore(0x34c0, mulmod(mload(0xf20), mload(0x34a0), f_q))
            mstore(0x34e0, addmod(mload(0x1480), sub(f_q, mload(0x14c0)), f_q))
            mstore(0x3500, mulmod(mload(0x34e0), mload(0x1e20), f_q))
            mstore(0x3520, addmod(mload(0x34c0), mload(0x3500), f_q))
            mstore(0x3540, mulmod(mload(0xf20), mload(0x3520), f_q))
            mstore(0x3560, mulmod(mload(0x34e0), mload(0x2920), f_q))
            mstore(0x3580, addmod(mload(0x1480), sub(f_q, mload(0x14a0)), f_q))
            mstore(0x35a0, mulmod(mload(0x3580), mload(0x3560), f_q))
            mstore(0x35c0, addmod(mload(0x3540), mload(0x35a0), f_q))
            mstore(0x35e0, mulmod(mload(0xf20), mload(0x35c0), f_q))
            mstore(0x3600, addmod(1, sub(f_q, mload(0x14e0)), f_q))
            mstore(0x3620, mulmod(mload(0x3600), mload(0x1e20), f_q))
            mstore(0x3640, addmod(mload(0x35e0), mload(0x3620), f_q))
            mstore(0x3660, mulmod(mload(0xf20), mload(0x3640), f_q))
            mstore(0x3680, mulmod(mload(0x14e0), mload(0x14e0), f_q))
            mstore(0x36a0, addmod(mload(0x3680), sub(f_q, mload(0x14e0)), f_q))
            mstore(0x36c0, mulmod(mload(0x36a0), mload(0x1d60), f_q))
            mstore(0x36e0, addmod(mload(0x3660), mload(0x36c0), f_q))
            mstore(0x3700, mulmod(mload(0xf20), mload(0x36e0), f_q))
            mstore(0x3720, addmod(mload(0x1520), mload(0xd20), f_q))
            mstore(0x3740, mulmod(mload(0x3720), mload(0x1500), f_q))
            mstore(0x3760, addmod(mload(0x1560), mload(0xd80), f_q))
            mstore(0x3780, mulmod(mload(0x3760), mload(0x3740), f_q))
            mstore(0x37a0, mulmod(mload(0x10c0), mload(0x1220), f_q))
            mstore(0x37c0, addmod(1, sub(f_q, mload(0x1220)), f_q))
            mstore(0x37e0, mulmod(mload(0x37c0), 0, f_q))
            mstore(0x3800, addmod(mload(0x37a0), mload(0x37e0), f_q))
            mstore(0x3820, mulmod(mload(0xbc0), mload(0x3800), f_q))
            mstore(0x3840, mulmod(mload(0x10e0), mload(0x1220), f_q))
            mstore(0x3860, mulmod(mload(0x37c0), 8, f_q))
            mstore(0x3880, addmod(mload(0x3840), mload(0x3860), f_q))
            mstore(0x38a0, addmod(mload(0x3820), mload(0x3880), f_q))
            mstore(0x38c0, addmod(mload(0x38a0), mload(0xd20), f_q))
            mstore(0x38e0, mulmod(mload(0x38c0), mload(0x14e0), f_q))
            mstore(0x3900, mulmod(mload(0xbc0), mload(0x11c0), f_q))
            mstore(0x3920, addmod(mload(0x3900), mload(0x11e0), f_q))
            mstore(0x3940, addmod(mload(0x3920), mload(0xd80), f_q))
            mstore(0x3960, mulmod(mload(0x3940), mload(0x38e0), f_q))
            mstore(0x3980, addmod(mload(0x3780), sub(f_q, mload(0x3960)), f_q))
            mstore(0x39a0, mulmod(mload(0x3980), mload(0x2920), f_q))
            mstore(0x39c0, addmod(mload(0x3700), mload(0x39a0), f_q))
            mstore(0x39e0, mulmod(mload(0xf20), mload(0x39c0), f_q))
            mstore(0x3a00, addmod(mload(0x1520), sub(f_q, mload(0x1560)), f_q))
            mstore(0x3a20, mulmod(mload(0x3a00), mload(0x1e20), f_q))
            mstore(0x3a40, addmod(mload(0x39e0), mload(0x3a20), f_q))
            mstore(0x3a60, mulmod(mload(0xf20), mload(0x3a40), f_q))
            mstore(0x3a80, mulmod(mload(0x3a00), mload(0x2920), f_q))
            mstore(0x3aa0, addmod(mload(0x1520), sub(f_q, mload(0x1540)), f_q))
            mstore(0x3ac0, mulmod(mload(0x3aa0), mload(0x3a80), f_q))
            mstore(0x3ae0, addmod(mload(0x3a60), mload(0x3ac0), f_q))
            mstore(0x3b00, mulmod(mload(0x1980), mload(0x1980), f_q))
            mstore(0x3b20, mulmod(mload(0x3b00), mload(0x1980), f_q))
            mstore(0x3b40, mulmod(mload(0x3b20), mload(0x1980), f_q))
            mstore(0x3b60, mulmod(1, mload(0x1980), f_q))
            mstore(0x3b80, mulmod(1, mload(0x3b00), f_q))
            mstore(0x3ba0, mulmod(1, mload(0x3b20), f_q))
            mstore(0x3bc0, mulmod(mload(0x3ae0), mload(0x19a0), f_q))
            mstore(0x3be0, mulmod(mload(0x1700), mload(0x1700), f_q))
            mstore(0x3c00, mulmod(mload(0x3be0), mload(0x1700), f_q))
            mstore(0x3c20, mulmod(mload(0x3c00), mload(0x1700), f_q))
            mstore(0x3c40, mulmod(mload(0x15a0), mload(0x15a0), f_q))
            mstore(0x3c60, mulmod(mload(0x3c40), mload(0x15a0), f_q))
            mstore(0x3c80, mulmod(mload(0x3c60), mload(0x15a0), f_q))
            mstore(0x3ca0, mulmod(mload(0x3c80), mload(0x15a0), f_q))
            mstore(0x3cc0, mulmod(mload(0x3ca0), mload(0x15a0), f_q))
            mstore(0x3ce0, mulmod(mload(0x3cc0), mload(0x15a0), f_q))
            mstore(0x3d00, mulmod(mload(0x3ce0), mload(0x15a0), f_q))
            mstore(0x3d20, mulmod(mload(0x3d00), mload(0x15a0), f_q))
            mstore(0x3d40, mulmod(mload(0x3d20), mload(0x15a0), f_q))
            mstore(0x3d60, mulmod(mload(0x3d40), mload(0x15a0), f_q))
            mstore(0x3d80, mulmod(mload(0x3d60), mload(0x15a0), f_q))
            mstore(0x3da0, mulmod(mload(0x3d80), mload(0x15a0), f_q))
            mstore(0x3dc0, mulmod(mload(0x3da0), mload(0x15a0), f_q))
            mstore(0x3de0, mulmod(mload(0x3dc0), mload(0x15a0), f_q))
            mstore(0x3e00, mulmod(mload(0x3de0), mload(0x15a0), f_q))
            mstore(0x3e20, mulmod(mload(0x3e00), mload(0x15a0), f_q))
            mstore(0x3e40, mulmod(mload(0x3e20), mload(0x15a0), f_q))
            mstore(0x3e60, mulmod(mload(0x3e40), mload(0x15a0), f_q))
            mstore(0x3e80, mulmod(mload(0x3e60), mload(0x15a0), f_q))
            mstore(0x3ea0, mulmod(mload(0x3e80), mload(0x15a0), f_q))
            mstore(0x3ec0, mulmod(mload(0x3ea0), mload(0x15a0), f_q))
            mstore(0x3ee0, mulmod(mload(0x3ec0), mload(0x15a0), f_q))
            mstore(0x3f00, mulmod(mload(0x3ee0), mload(0x15a0), f_q))
            mstore(0x3f20, mulmod(mload(0x3f00), mload(0x15a0), f_q))
            mstore(0x3f40, mulmod(mload(0x3f20), mload(0x15a0), f_q))
            mstore(0x3f60, mulmod(mload(0x3f40), mload(0x15a0), f_q))
            mstore(0x3f80, mulmod(mload(0x3f60), mload(0x15a0), f_q))
            mstore(0x3fa0, mulmod(mload(0x3f80), mload(0x15a0), f_q))
            mstore(0x3fc0, mulmod(mload(0x3fa0), mload(0x15a0), f_q))
            mstore(0x3fe0, mulmod(mload(0x3fc0), mload(0x15a0), f_q))
            mstore(0x4000, mulmod(sub(f_q, mload(0x10c0)), 1, f_q))
            mstore(0x4020, mulmod(sub(f_q, mload(0x10e0)), mload(0x15a0), f_q))
            mstore(0x4040, mulmod(1, mload(0x15a0), f_q))
            mstore(0x4060, addmod(mload(0x4000), mload(0x4020), f_q))
            mstore(0x4080, mulmod(sub(f_q, mload(0x1100)), mload(0x3c40), f_q))
            mstore(0x40a0, mulmod(1, mload(0x3c40), f_q))
            mstore(0x40c0, addmod(mload(0x4060), mload(0x4080), f_q))
            mstore(0x40e0, mulmod(sub(f_q, mload(0x13a0)), mload(0x3c60), f_q))
            mstore(0x4100, mulmod(1, mload(0x3c60), f_q))
            mstore(0x4120, addmod(mload(0x40c0), mload(0x40e0), f_q))
            mstore(0x4140, mulmod(sub(f_q, mload(0x1400)), mload(0x3c80), f_q))
            mstore(0x4160, mulmod(1, mload(0x3c80), f_q))
            mstore(0x4180, addmod(mload(0x4120), mload(0x4140), f_q))
            mstore(0x41a0, mulmod(sub(f_q, mload(0x1440)), mload(0x3ca0), f_q))
            mstore(0x41c0, mulmod(1, mload(0x3ca0), f_q))
            mstore(0x41e0, addmod(mload(0x4180), mload(0x41a0), f_q))
            mstore(0x4200, mulmod(sub(f_q, mload(0x1480)), mload(0x3cc0), f_q))
            mstore(0x4220, mulmod(1, mload(0x3cc0), f_q))
            mstore(0x4240, addmod(mload(0x41e0), mload(0x4200), f_q))
            mstore(0x4260, mulmod(sub(f_q, mload(0x14c0)), mload(0x3ce0), f_q))
            mstore(0x4280, mulmod(1, mload(0x3ce0), f_q))
            mstore(0x42a0, addmod(mload(0x4240), mload(0x4260), f_q))
            mstore(0x42c0, mulmod(sub(f_q, mload(0x14e0)), mload(0x3d00), f_q))
            mstore(0x42e0, mulmod(1, mload(0x3d00), f_q))
            mstore(0x4300, addmod(mload(0x42a0), mload(0x42c0), f_q))
            mstore(0x4320, mulmod(sub(f_q, mload(0x1520)), mload(0x3d20), f_q))
            mstore(0x4340, mulmod(1, mload(0x3d20), f_q))
            mstore(0x4360, addmod(mload(0x4300), mload(0x4320), f_q))
            mstore(0x4380, mulmod(sub(f_q, mload(0x1560)), mload(0x3d40), f_q))
            mstore(0x43a0, mulmod(1, mload(0x3d40), f_q))
            mstore(0x43c0, addmod(mload(0x4360), mload(0x4380), f_q))
            mstore(0x43e0, mulmod(sub(f_q, mload(0x1140)), mload(0x3d60), f_q))
            mstore(0x4400, mulmod(1, mload(0x3d60), f_q))
            mstore(0x4420, addmod(mload(0x43c0), mload(0x43e0), f_q))
            mstore(0x4440, mulmod(sub(f_q, mload(0x1160)), mload(0x3d80), f_q))
            mstore(0x4460, mulmod(1, mload(0x3d80), f_q))
            mstore(0x4480, addmod(mload(0x4420), mload(0x4440), f_q))
            mstore(0x44a0, mulmod(sub(f_q, mload(0x1180)), mload(0x3da0), f_q))
            mstore(0x44c0, mulmod(1, mload(0x3da0), f_q))
            mstore(0x44e0, addmod(mload(0x4480), mload(0x44a0), f_q))
            mstore(0x4500, mulmod(sub(f_q, mload(0x11a0)), mload(0x3dc0), f_q))
            mstore(0x4520, mulmod(1, mload(0x3dc0), f_q))
            mstore(0x4540, addmod(mload(0x44e0), mload(0x4500), f_q))
            mstore(0x4560, mulmod(sub(f_q, mload(0x11c0)), mload(0x3de0), f_q))
            mstore(0x4580, mulmod(1, mload(0x3de0), f_q))
            mstore(0x45a0, addmod(mload(0x4540), mload(0x4560), f_q))
            mstore(0x45c0, addmod(mload(0x44c0), mload(0x4580), f_q))
            mstore(0x45e0, mulmod(sub(f_q, mload(0x11e0)), mload(0x3e00), f_q))
            mstore(0x4600, mulmod(1, mload(0x3e00), f_q))
            mstore(0x4620, addmod(mload(0x45a0), mload(0x45e0), f_q))
            mstore(0x4640, mulmod(sub(f_q, mload(0x1200)), mload(0x3e20), f_q))
            mstore(0x4660, mulmod(1, mload(0x3e20), f_q))
            mstore(0x4680, addmod(mload(0x4620), mload(0x4640), f_q))
            mstore(0x46a0, mulmod(sub(f_q, mload(0x1220)), mload(0x3e40), f_q))
            mstore(0x46c0, mulmod(1, mload(0x3e40), f_q))
            mstore(0x46e0, addmod(mload(0x4680), mload(0x46a0), f_q))
            mstore(0x4700, mulmod(sub(f_q, mload(0x1240)), mload(0x3e60), f_q))
            mstore(0x4720, mulmod(1, mload(0x3e60), f_q))
            mstore(0x4740, addmod(mload(0x46e0), mload(0x4700), f_q))
            mstore(0x4760, mulmod(sub(f_q, mload(0x1260)), mload(0x3e80), f_q))
            mstore(0x4780, mulmod(1, mload(0x3e80), f_q))
            mstore(0x47a0, addmod(mload(0x4740), mload(0x4760), f_q))
            mstore(0x47c0, mulmod(sub(f_q, mload(0x1280)), mload(0x3ea0), f_q))
            mstore(0x47e0, mulmod(1, mload(0x3ea0), f_q))
            mstore(0x4800, addmod(mload(0x47a0), mload(0x47c0), f_q))
            mstore(0x4820, mulmod(sub(f_q, mload(0x12a0)), mload(0x3ec0), f_q))
            mstore(0x4840, mulmod(1, mload(0x3ec0), f_q))
            mstore(0x4860, addmod(mload(0x4800), mload(0x4820), f_q))
            mstore(0x4880, addmod(mload(0x4460), mload(0x4840), f_q))
            mstore(0x48a0, mulmod(sub(f_q, mload(0x12e0)), mload(0x3ee0), f_q))
            mstore(0x48c0, mulmod(1, mload(0x3ee0), f_q))
            mstore(0x48e0, addmod(mload(0x4860), mload(0x48a0), f_q))
            mstore(0x4900, mulmod(sub(f_q, mload(0x1300)), mload(0x3f00), f_q))
            mstore(0x4920, mulmod(1, mload(0x3f00), f_q))
            mstore(0x4940, addmod(mload(0x48e0), mload(0x4900), f_q))
            mstore(0x4960, mulmod(sub(f_q, mload(0x1320)), mload(0x3f20), f_q))
            mstore(0x4980, mulmod(1, mload(0x3f20), f_q))
            mstore(0x49a0, addmod(mload(0x4940), mload(0x4960), f_q))
            mstore(0x49c0, mulmod(sub(f_q, mload(0x1340)), mload(0x3f40), f_q))
            mstore(0x49e0, mulmod(1, mload(0x3f40), f_q))
            mstore(0x4a00, addmod(mload(0x49a0), mload(0x49c0), f_q))
            mstore(0x4a20, mulmod(sub(f_q, mload(0x1360)), mload(0x3f60), f_q))
            mstore(0x4a40, mulmod(1, mload(0x3f60), f_q))
            mstore(0x4a60, addmod(mload(0x4a00), mload(0x4a20), f_q))
            mstore(0x4a80, mulmod(sub(f_q, mload(0x1380)), mload(0x3f80), f_q))
            mstore(0x4aa0, mulmod(1, mload(0x3f80), f_q))
            mstore(0x4ac0, addmod(mload(0x4a60), mload(0x4a80), f_q))
            mstore(0x4ae0, mulmod(sub(f_q, mload(0x3bc0)), mload(0x3fa0), f_q))
            mstore(0x4b00, mulmod(1, mload(0x3fa0), f_q))
            mstore(0x4b20, mulmod(mload(0x3b60), mload(0x3fa0), f_q))
            mstore(0x4b40, mulmod(mload(0x3b80), mload(0x3fa0), f_q))
            mstore(0x4b60, mulmod(mload(0x3ba0), mload(0x3fa0), f_q))
            mstore(0x4b80, addmod(mload(0x4ac0), mload(0x4ae0), f_q))
            mstore(0x4ba0, mulmod(sub(f_q, mload(0x12c0)), mload(0x3fc0), f_q))
            mstore(0x4bc0, mulmod(1, mload(0x3fc0), f_q))
            mstore(0x4be0, addmod(mload(0x4b80), mload(0x4ba0), f_q))
            mstore(0x4c00, mulmod(mload(0x4be0), 1, f_q))
            mstore(0x4c20, mulmod(mload(0x4040), 1, f_q))
            mstore(0x4c40, mulmod(mload(0x40a0), 1, f_q))
            mstore(0x4c60, mulmod(mload(0x4100), 1, f_q))
            mstore(0x4c80, mulmod(mload(0x4160), 1, f_q))
            mstore(0x4ca0, mulmod(mload(0x41c0), 1, f_q))
            mstore(0x4cc0, mulmod(mload(0x4220), 1, f_q))
            mstore(0x4ce0, mulmod(mload(0x4280), 1, f_q))
            mstore(0x4d00, mulmod(mload(0x42e0), 1, f_q))
            mstore(0x4d20, mulmod(mload(0x4340), 1, f_q))
            mstore(0x4d40, mulmod(mload(0x43a0), 1, f_q))
            mstore(0x4d60, mulmod(mload(0x4400), 1, f_q))
            mstore(0x4d80, mulmod(mload(0x4880), 1, f_q))
            mstore(0x4da0, mulmod(mload(0x45c0), 1, f_q))
            mstore(0x4dc0, mulmod(mload(0x4520), 1, f_q))
            mstore(0x4de0, mulmod(mload(0x4600), 1, f_q))
            mstore(0x4e00, mulmod(mload(0x4660), 1, f_q))
            mstore(0x4e20, mulmod(mload(0x46c0), 1, f_q))
            mstore(0x4e40, mulmod(mload(0x4720), 1, f_q))
            mstore(0x4e60, mulmod(mload(0x4780), 1, f_q))
            mstore(0x4e80, mulmod(mload(0x47e0), 1, f_q))
            mstore(0x4ea0, mulmod(mload(0x48c0), 1, f_q))
            mstore(0x4ec0, mulmod(mload(0x4920), 1, f_q))
            mstore(0x4ee0, mulmod(mload(0x4980), 1, f_q))
            mstore(0x4f00, mulmod(mload(0x49e0), 1, f_q))
            mstore(0x4f20, mulmod(mload(0x4a40), 1, f_q))
            mstore(0x4f40, mulmod(mload(0x4aa0), 1, f_q))
            mstore(0x4f60, mulmod(mload(0x4b00), 1, f_q))
            mstore(0x4f80, mulmod(mload(0x4b20), 1, f_q))
            mstore(0x4fa0, mulmod(mload(0x4b40), 1, f_q))
            mstore(0x4fc0, mulmod(mload(0x4b60), 1, f_q))
            mstore(0x4fe0, mulmod(mload(0x4bc0), 1, f_q))
            mstore(0x5000, mulmod(sub(f_q, mload(0x1120)), 1, f_q))
            mstore(0x5020, mulmod(sub(f_q, mload(0x14a0)), mload(0x15a0), f_q))
            mstore(0x5040, addmod(mload(0x5000), mload(0x5020), f_q))
            mstore(0x5060, mulmod(sub(f_q, mload(0x1540)), mload(0x3c40), f_q))
            mstore(0x5080, addmod(mload(0x5040), mload(0x5060), f_q))
            mstore(0x50a0, mulmod(mload(0x5080), mload(0x1700), f_q))
            mstore(0x50c0, mulmod(1, mload(0x1700), f_q))
            mstore(0x50e0, mulmod(mload(0x4040), mload(0x1700), f_q))
            mstore(0x5100, mulmod(mload(0x40a0), mload(0x1700), f_q))
            mstore(0x5120, addmod(mload(0x4c00), mload(0x50a0), f_q))
            mstore(0x5140, addmod(mload(0x4c40), mload(0x50c0), f_q))
            mstore(0x5160, addmod(mload(0x4cc0), mload(0x50e0), f_q))
            mstore(0x5180, addmod(mload(0x4d20), mload(0x5100), f_q))
            mstore(0x51a0, mulmod(sub(f_q, mload(0x13c0)), 1, f_q))
            mstore(0x51c0, mulmod(sub(f_q, mload(0x1420)), mload(0x15a0), f_q))
            mstore(0x51e0, addmod(mload(0x51a0), mload(0x51c0), f_q))
            mstore(0x5200, mulmod(sub(f_q, mload(0x1460)), mload(0x3c40), f_q))
            mstore(0x5220, addmod(mload(0x51e0), mload(0x5200), f_q))
            mstore(0x5240, mulmod(sub(f_q, mload(0x1500)), mload(0x3c60), f_q))
            mstore(0x5260, addmod(mload(0x5220), mload(0x5240), f_q))
            mstore(0x5280, mulmod(mload(0x5260), mload(0x3be0), f_q))
            mstore(0x52a0, mulmod(1, mload(0x3be0), f_q))
            mstore(0x52c0, mulmod(mload(0x4040), mload(0x3be0), f_q))
            mstore(0x52e0, mulmod(mload(0x40a0), mload(0x3be0), f_q))
            mstore(0x5300, mulmod(mload(0x4100), mload(0x3be0), f_q))
            mstore(0x5320, addmod(mload(0x5120), mload(0x5280), f_q))
            mstore(0x5340, addmod(mload(0x4c60), mload(0x52a0), f_q))
            mstore(0x5360, addmod(mload(0x4c80), mload(0x52c0), f_q))
            mstore(0x5380, addmod(mload(0x4ca0), mload(0x52e0), f_q))
            mstore(0x53a0, addmod(mload(0x4d00), mload(0x5300), f_q))
            mstore(0x53c0, mulmod(sub(f_q, mload(0x13e0)), 1, f_q))
            mstore(0x53e0, mulmod(mload(0x53c0), mload(0x3c00), f_q))
            mstore(0x5400, mulmod(1, mload(0x3c00), f_q))
            mstore(0x5420, addmod(mload(0x5320), mload(0x53e0), f_q))
            mstore(0x5440, addmod(mload(0x5340), mload(0x5400), f_q))
            mstore(0x5460, mulmod(1, mload(0x1080), f_q))
            mstore(0x5480, mulmod(1, mload(0x5460), f_q))
            mstore(
                0x54a0,
                mulmod(
                    14686510910986211321976396297238126901237973400949744736326777596334651355305,
                    mload(0x1080),
                    f_q
                )
            )
            mstore(0x54c0, mulmod(mload(0x50c0), mload(0x54a0), f_q))
            mstore(
                0x54e0,
                mulmod(
                    5854133144571823792863860130267644613802765696134002830362054821530146160770,
                    mload(0x1080),
                    f_q
                )
            )
            mstore(0x5500, mulmod(mload(0x52a0), mload(0x54e0), f_q))
            mstore(
                0x5520,
                mulmod(
                    15837174511167031493871940795515473313759957271874477857633393696392913897559,
                    mload(0x1080),
                    f_q
                )
            )
            mstore(0x5540, mulmod(mload(0x5400), mload(0x5520), f_q))
            mstore(
                0x5560,
                0x0000000000000000000000000000000000000000000000000000000000000001
            )
            mstore(
                0x5580,
                0x0000000000000000000000000000000000000000000000000000000000000002
            )
            mstore(0x55a0, mload(0x5420))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5560, 0x60, 0x5560, 0x40), 1),
                success
            )
            mstore(0x55c0, mload(0x5560))
            mstore(0x55e0, mload(0x5580))
            mstore(0x5600, mload(0xae0))
            mstore(0x5620, mload(0xb00))
            success := and(
                eq(staticcall(gas(), 0x6, 0x55c0, 0x80, 0x55c0, 0x40), 1),
                success
            )
            mstore(0x5640, mload(0xb20))
            mstore(0x5660, mload(0xb40))
            mstore(0x5680, mload(0x4c20))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5640, 0x60, 0x5640, 0x40), 1),
                success
            )
            mstore(0x56a0, mload(0x55c0))
            mstore(0x56c0, mload(0x55e0))
            mstore(0x56e0, mload(0x5640))
            mstore(0x5700, mload(0x5660))
            success := and(
                eq(staticcall(gas(), 0x6, 0x56a0, 0x80, 0x56a0, 0x40), 1),
                success
            )
            mstore(0x5720, mload(0xb60))
            mstore(0x5740, mload(0xb80))
            mstore(0x5760, mload(0x5140))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5720, 0x60, 0x5720, 0x40), 1),
                success
            )
            mstore(0x5780, mload(0x56a0))
            mstore(0x57a0, mload(0x56c0))
            mstore(0x57c0, mload(0x5720))
            mstore(0x57e0, mload(0x5740))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5780, 0x80, 0x5780, 0x40), 1),
                success
            )
            mstore(0x5800, mload(0xdc0))
            mstore(0x5820, mload(0xde0))
            mstore(0x5840, mload(0x5440))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5800, 0x60, 0x5800, 0x40), 1),
                success
            )
            mstore(0x5860, mload(0x5780))
            mstore(0x5880, mload(0x57a0))
            mstore(0x58a0, mload(0x5800))
            mstore(0x58c0, mload(0x5820))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5860, 0x80, 0x5860, 0x40), 1),
                success
            )
            mstore(0x58e0, mload(0xe00))
            mstore(0x5900, mload(0xe20))
            mstore(0x5920, mload(0x5360))
            success := and(
                eq(staticcall(gas(), 0x7, 0x58e0, 0x60, 0x58e0, 0x40), 1),
                success
            )
            mstore(0x5940, mload(0x5860))
            mstore(0x5960, mload(0x5880))
            mstore(0x5980, mload(0x58e0))
            mstore(0x59a0, mload(0x5900))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5940, 0x80, 0x5940, 0x40), 1),
                success
            )
            mstore(0x59c0, mload(0xe40))
            mstore(0x59e0, mload(0xe60))
            mstore(0x5a00, mload(0x5380))
            success := and(
                eq(staticcall(gas(), 0x7, 0x59c0, 0x60, 0x59c0, 0x40), 1),
                success
            )
            mstore(0x5a20, mload(0x5940))
            mstore(0x5a40, mload(0x5960))
            mstore(0x5a60, mload(0x59c0))
            mstore(0x5a80, mload(0x59e0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5a20, 0x80, 0x5a20, 0x40), 1),
                success
            )
            mstore(0x5aa0, mload(0xc00))
            mstore(0x5ac0, mload(0xc20))
            mstore(0x5ae0, mload(0x5160))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5aa0, 0x60, 0x5aa0, 0x40), 1),
                success
            )
            mstore(0x5b00, mload(0x5a20))
            mstore(0x5b20, mload(0x5a40))
            mstore(0x5b40, mload(0x5aa0))
            mstore(0x5b60, mload(0x5ac0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5b00, 0x80, 0x5b00, 0x40), 1),
                success
            )
            mstore(0x5b80, mload(0xc40))
            mstore(0x5ba0, mload(0xc60))
            mstore(0x5bc0, mload(0x4ce0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5b80, 0x60, 0x5b80, 0x40), 1),
                success
            )
            mstore(0x5be0, mload(0x5b00))
            mstore(0x5c00, mload(0x5b20))
            mstore(0x5c20, mload(0x5b80))
            mstore(0x5c40, mload(0x5ba0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5be0, 0x80, 0x5be0, 0x40), 1),
                success
            )
            mstore(0x5c60, mload(0xe80))
            mstore(0x5c80, mload(0xea0))
            mstore(0x5ca0, mload(0x53a0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5c60, 0x60, 0x5c60, 0x40), 1),
                success
            )
            mstore(0x5cc0, mload(0x5be0))
            mstore(0x5ce0, mload(0x5c00))
            mstore(0x5d00, mload(0x5c60))
            mstore(0x5d20, mload(0x5c80))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5cc0, 0x80, 0x5cc0, 0x40), 1),
                success
            )
            mstore(0x5d40, mload(0xc80))
            mstore(0x5d60, mload(0xca0))
            mstore(0x5d80, mload(0x5180))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5d40, 0x60, 0x5d40, 0x40), 1),
                success
            )
            mstore(0x5da0, mload(0x5cc0))
            mstore(0x5dc0, mload(0x5ce0))
            mstore(0x5de0, mload(0x5d40))
            mstore(0x5e00, mload(0x5d60))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5da0, 0x80, 0x5da0, 0x40), 1),
                success
            )
            mstore(0x5e20, mload(0xcc0))
            mstore(0x5e40, mload(0xce0))
            mstore(0x5e60, mload(0x4d40))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5e20, 0x60, 0x5e20, 0x40), 1),
                success
            )
            mstore(0x5e80, mload(0x5da0))
            mstore(0x5ea0, mload(0x5dc0))
            mstore(0x5ec0, mload(0x5e20))
            mstore(0x5ee0, mload(0x5e40))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5e80, 0x80, 0x5e80, 0x40), 1),
                success
            )
            mstore(
                0x5f00,
                0x1be192e3d168c1d83636ccae13aabae9f3b047c4f7e9e489d7b390af948135d1
            )
            mstore(
                0x5f20,
                0x274a71674bea048409754b1e7eaec4840218923a6cb5416fd1bf9976ae7c4d0a
            )
            mstore(0x5f40, mload(0x4d60))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5f00, 0x60, 0x5f00, 0x40), 1),
                success
            )
            mstore(0x5f60, mload(0x5e80))
            mstore(0x5f80, mload(0x5ea0))
            mstore(0x5fa0, mload(0x5f00))
            mstore(0x5fc0, mload(0x5f20))
            success := and(
                eq(staticcall(gas(), 0x6, 0x5f60, 0x80, 0x5f60, 0x40), 1),
                success
            )
            mstore(
                0x5fe0,
                0x0000000000000000000000000000000000000000000000000000000000000000
            )
            mstore(
                0x6000,
                0x0000000000000000000000000000000000000000000000000000000000000000
            )
            mstore(0x6020, mload(0x4d80))
            success := and(
                eq(staticcall(gas(), 0x7, 0x5fe0, 0x60, 0x5fe0, 0x40), 1),
                success
            )
            mstore(0x6040, mload(0x5f60))
            mstore(0x6060, mload(0x5f80))
            mstore(0x6080, mload(0x5fe0))
            mstore(0x60a0, mload(0x6000))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6040, 0x80, 0x6040, 0x40), 1),
                success
            )
            mstore(
                0x60c0,
                0x2d6084bba456524375a8f743bfb6f94ed67750857d6f6f34bdb985dc0d072eaa
            )
            mstore(
                0x60e0,
                0x2b6b1c43e978e6ea1dcfd7f4770aff66d92f84bb7dfd0e7df58005dee64c1fe1
            )
            mstore(0x6100, mload(0x4da0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x60c0, 0x60, 0x60c0, 0x40), 1),
                success
            )
            mstore(0x6120, mload(0x6040))
            mstore(0x6140, mload(0x6060))
            mstore(0x6160, mload(0x60c0))
            mstore(0x6180, mload(0x60e0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6120, 0x80, 0x6120, 0x40), 1),
                success
            )
            mstore(
                0x61a0,
                0x1e97dbe4032677e0fb8f7c87e891dd9dcc6c15615b006d2803dbaefe900d5f6e
            )
            mstore(
                0x61c0,
                0x19ddcdf1621fbe0c81294a0266950ca91b942138a6fe1acbc034b42152795266
            )
            mstore(0x61e0, mload(0x4dc0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x61a0, 0x60, 0x61a0, 0x40), 1),
                success
            )
            mstore(0x6200, mload(0x6120))
            mstore(0x6220, mload(0x6140))
            mstore(0x6240, mload(0x61a0))
            mstore(0x6260, mload(0x61c0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6200, 0x80, 0x6200, 0x40), 1),
                success
            )
            mstore(
                0x6280,
                0x1ec1c898607708683e156bd52f484b1ee1ae362846ad277680a0d04960b454e0
            )
            mstore(
                0x62a0,
                0x2272bc7032b796476a9a084c439af89fd7726feab7c578b65d309d724d689e03
            )
            mstore(0x62c0, mload(0x4de0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6280, 0x60, 0x6280, 0x40), 1),
                success
            )
            mstore(0x62e0, mload(0x6200))
            mstore(0x6300, mload(0x6220))
            mstore(0x6320, mload(0x6280))
            mstore(0x6340, mload(0x62a0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x62e0, 0x80, 0x62e0, 0x40), 1),
                success
            )
            mstore(
                0x6360,
                0x153fba64c92d7ac26fffc39627419e0e25de064c392986e5297ef3d628ca500f
            )
            mstore(
                0x6380,
                0x1a5c8453026d7e65f0c561febb0c13041945b4bd7951ad0612914619498aeadd
            )
            mstore(0x63a0, mload(0x4e00))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6360, 0x60, 0x6360, 0x40), 1),
                success
            )
            mstore(0x63c0, mload(0x62e0))
            mstore(0x63e0, mload(0x6300))
            mstore(0x6400, mload(0x6360))
            mstore(0x6420, mload(0x6380))
            success := and(
                eq(staticcall(gas(), 0x6, 0x63c0, 0x80, 0x63c0, 0x40), 1),
                success
            )
            mstore(
                0x6440,
                0x1b72ede0fd87ca4eef2533cd5b49ffd7fbf72bc41551ca78caa898eeaee95cc9
            )
            mstore(
                0x6460,
                0x10633b1c7af1d0bf52306e684c00f280172446c40d012fd000ddc440cdb73e76
            )
            mstore(0x6480, mload(0x4e20))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6440, 0x60, 0x6440, 0x40), 1),
                success
            )
            mstore(0x64a0, mload(0x63c0))
            mstore(0x64c0, mload(0x63e0))
            mstore(0x64e0, mload(0x6440))
            mstore(0x6500, mload(0x6460))
            success := and(
                eq(staticcall(gas(), 0x6, 0x64a0, 0x80, 0x64a0, 0x40), 1),
                success
            )
            mstore(
                0x6520,
                0x1c59d621136ff917103c9d9405aa16de142f20c425d231f4d8aa4f646ca11cdf
            )
            mstore(
                0x6540,
                0x03dedd59888c5578f7c099dc8b156a148537e3282d2253d65f98f5e3a33a1b58
            )
            mstore(0x6560, mload(0x4e40))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6520, 0x60, 0x6520, 0x40), 1),
                success
            )
            mstore(0x6580, mload(0x64a0))
            mstore(0x65a0, mload(0x64c0))
            mstore(0x65c0, mload(0x6520))
            mstore(0x65e0, mload(0x6540))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6580, 0x80, 0x6580, 0x40), 1),
                success
            )
            mstore(
                0x6600,
                0x2128a9e0bc05a0576865d18abf9e65020a042a4fb4acb654fcb0981bd00a8871
            )
            mstore(
                0x6620,
                0x1bc2e9f9c70de84798db59cbb87633abc9de2ed736543b0f2c66d66b171cad77
            )
            mstore(0x6640, mload(0x4e60))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6600, 0x60, 0x6600, 0x40), 1),
                success
            )
            mstore(0x6660, mload(0x6580))
            mstore(0x6680, mload(0x65a0))
            mstore(0x66a0, mload(0x6600))
            mstore(0x66c0, mload(0x6620))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6660, 0x80, 0x6660, 0x40), 1),
                success
            )
            mstore(
                0x66e0,
                0x2d88452b79928ab39066da9b8578c2ec8eb515334a5fd8e5e841aa98fa366769
            )
            mstore(
                0x6700,
                0x10c6576695a2a1e506dfb2efc181d23b121219635b9a2f1a2bd0493b84d0a7ce
            )
            mstore(0x6720, mload(0x4e80))
            success := and(
                eq(staticcall(gas(), 0x7, 0x66e0, 0x60, 0x66e0, 0x40), 1),
                success
            )
            mstore(0x6740, mload(0x6660))
            mstore(0x6760, mload(0x6680))
            mstore(0x6780, mload(0x66e0))
            mstore(0x67a0, mload(0x6700))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6740, 0x80, 0x6740, 0x40), 1),
                success
            )
            mstore(
                0x67c0,
                0x10366d9783e511dce4ae23fb2b18de7c2ec6dd5ce273a3f564357828c0a3447c
            )
            mstore(
                0x67e0,
                0x0c1a7c3d52e1928dce53eb1ff24f25dd166ff08eba69376369fd63ea83a170cc
            )
            mstore(0x6800, mload(0x4ea0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x67c0, 0x60, 0x67c0, 0x40), 1),
                success
            )
            mstore(0x6820, mload(0x6740))
            mstore(0x6840, mload(0x6760))
            mstore(0x6860, mload(0x67c0))
            mstore(0x6880, mload(0x67e0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6820, 0x80, 0x6820, 0x40), 1),
                success
            )
            mstore(
                0x68a0,
                0x113a5f86dcf279ef296f5537004bc5dfd121f195c05c1645c32cef38c8a06507
            )
            mstore(
                0x68c0,
                0x11cd0779694fc207569f6f8f72a0829d11e5c09359f8d5e282f249395d3181cf
            )
            mstore(0x68e0, mload(0x4ec0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x68a0, 0x60, 0x68a0, 0x40), 1),
                success
            )
            mstore(0x6900, mload(0x6820))
            mstore(0x6920, mload(0x6840))
            mstore(0x6940, mload(0x68a0))
            mstore(0x6960, mload(0x68c0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6900, 0x80, 0x6900, 0x40), 1),
                success
            )
            mstore(
                0x6980,
                0x20601c69ca520d1b2138a32878f4d836fbfb56de79810e323affe1b6e8bca276
            )
            mstore(
                0x69a0,
                0x03c819835ed075be031b6f73a4b89356bfd699072cb37bd97322e5d88aa0172c
            )
            mstore(0x69c0, mload(0x4ee0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6980, 0x60, 0x6980, 0x40), 1),
                success
            )
            mstore(0x69e0, mload(0x6900))
            mstore(0x6a00, mload(0x6920))
            mstore(0x6a20, mload(0x6980))
            mstore(0x6a40, mload(0x69a0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x69e0, 0x80, 0x69e0, 0x40), 1),
                success
            )
            mstore(
                0x6a60,
                0x0ac71bdb001cb284514d7b640ef32ded39098659e0e1f9cea190614d6cfb7260
            )
            mstore(
                0x6a80,
                0x0a0f341c3d4ece0621e2f91b0b5ec6ccfc6d94b175b4fd213328e2934b5eb554
            )
            mstore(0x6aa0, mload(0x4f00))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6a60, 0x60, 0x6a60, 0x40), 1),
                success
            )
            mstore(0x6ac0, mload(0x69e0))
            mstore(0x6ae0, mload(0x6a00))
            mstore(0x6b00, mload(0x6a60))
            mstore(0x6b20, mload(0x6a80))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6ac0, 0x80, 0x6ac0, 0x40), 1),
                success
            )
            mstore(
                0x6b40,
                0x1588e43c9076b9d60f23a5351e95ca4d199149c5c0954468da260832713ec9b2
            )
            mstore(
                0x6b60,
                0x29a44c1faac4c382d120bcdb6dcfde5158f4b84bdc86ee08a431dc415dfd8891
            )
            mstore(0x6b80, mload(0x4f20))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6b40, 0x60, 0x6b40, 0x40), 1),
                success
            )
            mstore(0x6ba0, mload(0x6ac0))
            mstore(0x6bc0, mload(0x6ae0))
            mstore(0x6be0, mload(0x6b40))
            mstore(0x6c00, mload(0x6b60))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6ba0, 0x80, 0x6ba0, 0x40), 1),
                success
            )
            mstore(
                0x6c20,
                0x25c102142760232f80da42040491c6c670d0a0271ff5b9dc92f1d13ec514b390
            )
            mstore(
                0x6c40,
                0x18ae2bff827b6ac52cd095c9b7d0f13e9d8716319af35d20fa8e94c06a23ed7c
            )
            mstore(0x6c60, mload(0x4f40))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6c20, 0x60, 0x6c20, 0x40), 1),
                success
            )
            mstore(0x6c80, mload(0x6ba0))
            mstore(0x6ca0, mload(0x6bc0))
            mstore(0x6cc0, mload(0x6c20))
            mstore(0x6ce0, mload(0x6c40))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6c80, 0x80, 0x6c80, 0x40), 1),
                success
            )
            mstore(0x6d00, mload(0xf60))
            mstore(0x6d20, mload(0xf80))
            mstore(0x6d40, mload(0x4f60))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6d00, 0x60, 0x6d00, 0x40), 1),
                success
            )
            mstore(0x6d60, mload(0x6c80))
            mstore(0x6d80, mload(0x6ca0))
            mstore(0x6da0, mload(0x6d00))
            mstore(0x6dc0, mload(0x6d20))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6d60, 0x80, 0x6d60, 0x40), 1),
                success
            )
            mstore(0x6de0, mload(0xfa0))
            mstore(0x6e00, mload(0xfc0))
            mstore(0x6e20, mload(0x4f80))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6de0, 0x60, 0x6de0, 0x40), 1),
                success
            )
            mstore(0x6e40, mload(0x6d60))
            mstore(0x6e60, mload(0x6d80))
            mstore(0x6e80, mload(0x6de0))
            mstore(0x6ea0, mload(0x6e00))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6e40, 0x80, 0x6e40, 0x40), 1),
                success
            )
            mstore(0x6ec0, mload(0xfe0))
            mstore(0x6ee0, mload(0x1000))
            mstore(0x6f00, mload(0x4fa0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6ec0, 0x60, 0x6ec0, 0x40), 1),
                success
            )
            mstore(0x6f20, mload(0x6e40))
            mstore(0x6f40, mload(0x6e60))
            mstore(0x6f60, mload(0x6ec0))
            mstore(0x6f80, mload(0x6ee0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x6f20, 0x80, 0x6f20, 0x40), 1),
                success
            )
            mstore(0x6fa0, mload(0x1020))
            mstore(0x6fc0, mload(0x1040))
            mstore(0x6fe0, mload(0x4fc0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x6fa0, 0x60, 0x6fa0, 0x40), 1),
                success
            )
            mstore(0x7000, mload(0x6f20))
            mstore(0x7020, mload(0x6f40))
            mstore(0x7040, mload(0x6fa0))
            mstore(0x7060, mload(0x6fc0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7000, 0x80, 0x7000, 0x40), 1),
                success
            )
            mstore(0x7080, mload(0xec0))
            mstore(0x70a0, mload(0xee0))
            mstore(0x70c0, mload(0x4fe0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x7080, 0x60, 0x7080, 0x40), 1),
                success
            )
            mstore(0x70e0, mload(0x7000))
            mstore(0x7100, mload(0x7020))
            mstore(0x7120, mload(0x7080))
            mstore(0x7140, mload(0x70a0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x70e0, 0x80, 0x70e0, 0x40), 1),
                success
            )
            mstore(0x7160, mload(0x15e0))
            mstore(0x7180, mload(0x1600))
            mstore(0x71a0, mload(0x5480))
            success := and(
                eq(staticcall(gas(), 0x7, 0x7160, 0x60, 0x7160, 0x40), 1),
                success
            )
            mstore(0x71c0, mload(0x70e0))
            mstore(0x71e0, mload(0x7100))
            mstore(0x7200, mload(0x7160))
            mstore(0x7220, mload(0x7180))
            success := and(
                eq(staticcall(gas(), 0x6, 0x71c0, 0x80, 0x71c0, 0x40), 1),
                success
            )
            mstore(0x7240, mload(0x1620))
            mstore(0x7260, mload(0x1640))
            mstore(0x7280, mload(0x54c0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x7240, 0x60, 0x7240, 0x40), 1),
                success
            )
            mstore(0x72a0, mload(0x71c0))
            mstore(0x72c0, mload(0x71e0))
            mstore(0x72e0, mload(0x7240))
            mstore(0x7300, mload(0x7260))
            success := and(
                eq(staticcall(gas(), 0x6, 0x72a0, 0x80, 0x72a0, 0x40), 1),
                success
            )
            mstore(0x7320, mload(0x1660))
            mstore(0x7340, mload(0x1680))
            mstore(0x7360, mload(0x5500))
            success := and(
                eq(staticcall(gas(), 0x7, 0x7320, 0x60, 0x7320, 0x40), 1),
                success
            )
            mstore(0x7380, mload(0x72a0))
            mstore(0x73a0, mload(0x72c0))
            mstore(0x73c0, mload(0x7320))
            mstore(0x73e0, mload(0x7340))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7380, 0x80, 0x7380, 0x40), 1),
                success
            )
            mstore(0x7400, mload(0x16a0))
            mstore(0x7420, mload(0x16c0))
            mstore(0x7440, mload(0x5540))
            success := and(
                eq(staticcall(gas(), 0x7, 0x7400, 0x60, 0x7400, 0x40), 1),
                success
            )
            mstore(0x7460, mload(0x7380))
            mstore(0x7480, mload(0x73a0))
            mstore(0x74a0, mload(0x7400))
            mstore(0x74c0, mload(0x7420))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7460, 0x80, 0x7460, 0x40), 1),
                success
            )
            mstore(0x74e0, mload(0x1620))
            mstore(0x7500, mload(0x1640))
            mstore(0x7520, mload(0x50c0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x74e0, 0x60, 0x74e0, 0x40), 1),
                success
            )
            mstore(0x7540, mload(0x15e0))
            mstore(0x7560, mload(0x1600))
            mstore(0x7580, mload(0x74e0))
            mstore(0x75a0, mload(0x7500))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7540, 0x80, 0x7540, 0x40), 1),
                success
            )
            mstore(0x75c0, mload(0x1660))
            mstore(0x75e0, mload(0x1680))
            mstore(0x7600, mload(0x52a0))
            success := and(
                eq(staticcall(gas(), 0x7, 0x75c0, 0x60, 0x75c0, 0x40), 1),
                success
            )
            mstore(0x7620, mload(0x7540))
            mstore(0x7640, mload(0x7560))
            mstore(0x7660, mload(0x75c0))
            mstore(0x7680, mload(0x75e0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7620, 0x80, 0x7620, 0x40), 1),
                success
            )
            mstore(0x76a0, mload(0x16a0))
            mstore(0x76c0, mload(0x16c0))
            mstore(0x76e0, mload(0x5400))
            success := and(
                eq(staticcall(gas(), 0x7, 0x76a0, 0x60, 0x76a0, 0x40), 1),
                success
            )
            mstore(0x7700, mload(0x7620))
            mstore(0x7720, mload(0x7640))
            mstore(0x7740, mload(0x76a0))
            mstore(0x7760, mload(0x76c0))
            success := and(
                eq(staticcall(gas(), 0x6, 0x7700, 0x80, 0x7700, 0x40), 1),
                success
            )
            mstore(0x7780, mload(0x7460))
            mstore(0x77a0, mload(0x7480))
            mstore(
                0x77c0,
                0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2
            )
            mstore(
                0x77e0,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            )
            mstore(
                0x7800,
                0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b
            )
            mstore(
                0x7820,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            )
            mstore(0x7840, mload(0x7700))
            mstore(0x7860, mload(0x7720))
            mstore(
                0x7880,
                0x186282957db913abd99f91db59fe69922e95040603ef44c0bd7aa3adeef8f5ac
            )
            mstore(
                0x78a0,
                0x17944351223333f260ddc3b4af45191b856689eda9eab5cbcddbbe570ce860d2
            )
            mstore(
                0x78c0,
                0x06d971ff4a7467c3ec596ed6efc674572e32fd6f52b721f97e35b0b3d3546753
            )
            mstore(
                0x78e0,
                0x06ecdb9f9567f59ed2eee36e1e1d58797fd13cc97fafc2910f5e8a12f202fa9a
            )
            success := and(
                eq(staticcall(gas(), 0x8, 0x7780, 0x180, 0x7780, 0x20), 1),
                success
            )
            success := and(eq(mload(0x7780), 1), success)
        }
        return success;
    }
}