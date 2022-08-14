// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDai} from "./IDai.sol";
import {IERC20OrderRouter} from "./IERC20OrderRouter.sol";

//import "hardhat/console.sol";

contract RelayProxy {
    IDai constant dai = IDai(address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063));
    IERC20OrderRouter constant router = IERC20OrderRouter(address(0x0c2c2963A4353FfD839590f7cb1E783688378814));

    event ReceivedEvent(uint256 amount, uint256 nonce, address signer, address spender);
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

    //    constructor(IDai _dai, IERC20OrderRouter _router) {
    //        dai = _dai;
    //        router = _router;
    //    }

    function limitOrder(
        address payable _signer,
        uint256 _amount,
        EIP712DaiPermitTxData calldata _daiPermit,
        LimitOrder calldata _order
    ) external {
//        console.log("limitOrder _signer: %o, _amount: %o, nonce: %o ", _signer, _amount, _daiPermit.nonce);
        emit ReceivedEvent(_amount, _daiPermit.nonce, _signer, _daiPermit.spender);
        //        address thisAddress = address(this);
//        dai.permit(
//            _signer,
//            _daiPermit.spender,
//            _daiPermit.nonce,
//            _daiPermit.expiry,
//            _daiPermit.allowed,
//            _daiPermit.v,
//            _daiPermit.r,
//            _daiPermit.s
//        );

        //dai.transferFrom(_signer, thisAddress, _amount);
        //dai.approve(address(router), _amount);

        //router.depositToken(_amount, _order.module, _order.inputToken, _signer, _order.witness, _order.data, _order.secret);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDai {
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        uint256 _amount,
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external;
}