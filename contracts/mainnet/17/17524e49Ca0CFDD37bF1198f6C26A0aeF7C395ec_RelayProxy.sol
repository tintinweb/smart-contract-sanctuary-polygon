// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDai} from "./IDai.sol";
import {IERC20OrderRouter} from "./IERC20OrderRouter.sol";

contract RelayProxy {
    IDai constant dai =
        IDai(address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063));
    IERC20OrderRouter constant router =
        IERC20OrderRouter(address(0x0c2c2963A4353FfD839590f7cb1E783688378814));

    struct EIP712DaiPermitTxData {
        uint256 nonce;
        uint256 expiry;
        address spender;
        bool allowed;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct LimitOrder {
        address module;
        address inputToken;
        address witness;
        bytes data;
        bytes32 secret;
    }

    function limitOrder(
        address payable signer,
        uint256 amount,
        EIP712DaiPermitTxData calldata daiPermit,
        LimitOrder calldata order
    ) external {

        dai.permit(
            signer,
            daiPermit.spender,
            daiPermit.nonce,
            daiPermit.expiry,
            daiPermit.allowed,
            daiPermit.v,
            daiPermit.r,
            daiPermit.s
        );
        dai.transferFrom(signer, address(this), amount);
        dai.approve(address(router), amount);

        router.depositToken(
            amount,
            order.module,
            order.inputToken,
            signer,
            order.witness,
            order.data,
            order.secret
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDai {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20OrderRouter {
    function depositToken(
        uint256 amount,
        address module,
        address inputToken,
        address payable owner,
        address witness,
        bytes calldata data,
        bytes32 secret
    ) external;
}