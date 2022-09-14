// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IBavePayV1Union.sol";
import "./interfaces/IBavePayV1Factory.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";

contract BavePayV1Union is IBavePayV1Union {
    using SafeMath for uint256;

    address public ownerAcct;
    address public ownerOper;
    address public factory;
    uint256 public unionId;
    uint256 public allPaymentsLength;
    mapping(uint256 => Payment) public payments;

    struct Payment {
        mapping(address => uint256) balanceOf;
        mapping(address => bool) allowedToken;
        address[] allTokens;
        address clientAcct;
        address clientOper;
        uint256 rate;
        uint256 paymentId;
    }

    constructor(
        address _ownerAcct,
        address _ownerOper,
        uint256 _unionId
    ) {
        ownerAcct = _ownerAcct;
        ownerOper = _ownerOper;
        unionId = _unionId;
        factory = msg.sender;
        allPaymentsLength = 0;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp);
        _;
    }
    modifier onlyOwnerOper() {
        require(msg.sender == ownerOper);
        _;
    }
    modifier jointCtrl(uint256 paymentId) {
        require(
            msg.sender == ownerOper ||
                msg.sender == payments[paymentId].clientOper
        );
        _;
    }

    function getBalanceOf(uint256 paymentId, address tokenAddr)
        external
        view
        returns (uint256)
    {
        return payments[paymentId].balanceOf[tokenAddr];
    }

    function getAllowedToken(uint256 paymentId, address tokenAddr)
        external
        view
        returns (bool)
    {
        return payments[paymentId].allowedToken[tokenAddr];
    }

    function getAllTokensLength(uint256 paymentId)
        external
        view
        returns (uint256)
    {
        return payments[paymentId].allTokens.length;
    }

    function getAllTokens(uint256 paymentId, uint256 index)
        external
        view
        returns (address)
    {
        return payments[paymentId].allTokens[index];
    }

    function commissionInfo(uint256 paymentId, uint256 balance)
        public
        view
        returns (uint256 commissionAmt)
    {
        commissionAmt = (balance * payments[paymentId].rate) / 10000;
        return (commissionAmt);
    }

    function createPayment(
        address _clientAcct,
        address _clientOper,
        address[] memory _tokens,
        uint256 _rate
    ) external onlyOwnerOper {
        uint256 _paymentId = allPaymentsLength++;
        Payment storage p = payments[_paymentId];
        p.clientAcct = _clientAcct;
        p.clientOper = _clientOper;
        p.rate = _rate;
        p.paymentId = _paymentId;
        p.allTokens = _tokens;
        emit PaymentCreated(unionId, _paymentId);
        emit ClientChanged(unionId, _paymentId, 0, address(0), _clientAcct);
        emit ClientChanged(unionId, _paymentId, 1, address(0), _clientOper);
        for (uint256 i = 0; i < _tokens.length; i++) {
            p.allowedToken[_tokens[i]] = true;
            emit TokenChanged(unionId, _paymentId, _tokens[i], true);
        }
    }

    function paymentNative(uint256 paymentId, uint256 deadline)
        external
        payable
        ensure(deadline)
    {
        require(msg.value > 0);
        uint256 commission = commissionInfo(paymentId, msg.value);
        uint256 balance = msg.value.sub(commission);
        Payment storage p = payments[paymentId];
        p.balanceOf[address(0)] = p.balanceOf[address(0)].add(balance);
        emit Ledger(
            unionId,
            paymentId,
            address(0),
            msg.sender,
            address(this),
            msg.value
        );
        emit Ledger(
            unionId,
            paymentId,
            address(0),
            address(this),
            ownerAcct,
            commission
        );
        payable(ownerAcct).transfer(commission);
    }

    function paymentToken(
        uint256 paymentId,
        address tokenAddr,
        uint256 amount,
        uint256 deadline
    ) external ensure(deadline) {
        require(amount > 0);
        Payment storage p = payments[paymentId];
        require(p.allowedToken[tokenAddr]);
        uint256 commission = commissionInfo(paymentId, amount);
        uint256 balance = amount.sub(commission);
        p.balanceOf[tokenAddr] = p.balanceOf[tokenAddr].add(balance);
        emit Ledger(
            unionId,
            paymentId,
            tokenAddr,
            msg.sender,
            address(this),
            amount
        );
        emit Ledger(
            unionId,
            paymentId,
            tokenAddr,
            address(this),
            ownerAcct,
            commission
        );
        _safeTransferFrom(tokenAddr, msg.sender, address(this), amount);
        _safeTransfer(tokenAddr, ownerAcct, commission);
    }

    function withdraw(uint256 paymentId, address tokenAddr)
        public
        jointCtrl(paymentId)
    {
        Payment storage p = payments[paymentId];
        require(tokenAddr == address(0) || p.allowedToken[tokenAddr]);
        uint256 balance = p.balanceOf[tokenAddr];
        if (balance > 0) {
            p.balanceOf[tokenAddr] = p.balanceOf[tokenAddr].sub(balance);
            emit Ledger(
                unionId,
                paymentId,
                tokenAddr,
                address(this),
                p.clientAcct,
                balance
            );
            if (tokenAddr == address(0)) {
                payable(p.clientAcct).transfer(balance);
            } else {
                _safeTransfer(tokenAddr, p.clientAcct, balance);
            }
        }
    }

    function withdrawAll(uint256 paymentId) external jointCtrl(paymentId) {
        Payment storage p = payments[paymentId];
        for (uint256 i = 0; i < p.allTokens.length; i++) {
            withdraw(paymentId, p.allTokens[i]);
        }
        withdraw(paymentId, address(0));
    }

    function ownerWithdraw(address tokenAddr) external onlyOwnerOper {
        uint256 subBalance;
        for (uint256 i = 0; i < allPaymentsLength; i++) {
            Payment storage p = payments[i];
            subBalance += p.balanceOf[tokenAddr];
        }
        if (tokenAddr == address(0)) {
            uint256 balance = (address(this).balance).sub(subBalance);
            require(balance > 0);
            payable(ownerAcct).transfer(balance);
        } else {
            uint256 balance = (IERC20(tokenAddr).balanceOf(address(this))).sub(
                subBalance
            );
            require(balance > 0);
            _safeTransfer(tokenAddr, ownerAcct, balance);
        }
    }

    function pushToken(uint256 paymentId, address[] memory _tokens)
        external
        onlyOwnerOper
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            Payment storage p = payments[paymentId];
            require(!p.allowedToken[token]);
            p.allowedToken[token] = true;
            p.allTokens.push(token);
            emit TokenChanged(unionId, paymentId, token, true);
        }
    }

    function removeToken(uint256 paymentId, uint256 _index)
        external
        onlyOwnerOper
    {
        Payment storage p = payments[paymentId];
        address token = p.allTokens[_index];
        require(p.allowedToken[token]);
        p.allowedToken[token] = false;
        for (uint256 i = _index; i < p.allTokens.length - 1; i++) {
            p.allTokens[i] = p.allTokens[i + 1];
        }
        p.allTokens.pop();
        emit TokenChanged(unionId, paymentId, token, false);
    }

    function setOwnerAcct(address _ownerAcct) external onlyOwnerOper {
        require(_ownerAcct != address(0));
        emit OwnerChanged(unionId, 0, ownerAcct, _ownerAcct);
        ownerAcct = _ownerAcct;
    }

    function setOwnerOper(address _ownerOper) external onlyOwnerOper {
        require(_ownerOper != address(0));
        emit OwnerChanged(unionId, 1, ownerOper, _ownerOper);
        ownerOper = _ownerOper;
    }

    function setClientAcct(uint256 paymentId, address _clientAcct)
        external
        jointCtrl(paymentId)
    {
        require(_clientAcct != address(0));
        Payment storage p = payments[paymentId];
        p.clientAcct = _clientAcct;
        emit ClientChanged(unionId, paymentId, 0, p.clientAcct, _clientAcct);
    }

    function setClientOper(uint256 paymentId, address _clientOper)
        external
        jointCtrl(paymentId)
    {
        require(_clientOper != address(0));
        Payment storage p = payments[paymentId];
        p.clientOper = _clientOper;
        emit ClientChanged(unionId, paymentId, 1, p.clientOper, _clientOper);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Union {
    event PaymentCreated(uint256 unionId, uint256 paymentId);
    event OwnerChanged(
        uint256 unionId,
        uint256 class,
        address indexed oldAddress,
        address indexed newAddress
    );
    event ClientChanged(
        uint256 unionId,
        uint256 paymentId,
        uint256 class,
        address indexed oldAddress,
        address indexed newAddress
    );
    event TokenChanged(
        uint256 unionId,
        uint256 paymentId,
        address indexed token,
        bool boolean
    );
    event Ledger(
        uint256 unionId,
        uint256 paymentId,
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    function ownerAcct() external view returns (address);
    function ownerOper() external view returns (address);
    function factory() external view returns (address);
    function unionId() external view returns (uint256);
    function allPaymentsLength() external view returns (uint256);

    function getBalanceOf(uint256, address) external view returns (uint256);
    function getAllowedToken(uint256, address) external view returns (bool);
    function getAllTokensLength(uint256) external view returns (uint256);
    function getAllTokens(uint256, uint256) external view returns (address);
    function commissionInfo(uint256, uint256) external view returns (uint256);
    function createPayment(
        address,
        address,
        address[] memory,
        uint256
    ) external;
    function paymentNative(uint256, uint256) external payable;
    function paymentToken(
        uint256,
        address,
        uint256,
        uint256
    ) external;
    function withdraw(uint256, address) external;
    function withdrawAll(uint256) external;
    function ownerWithdraw(address) external;
    function pushToken(uint256, address[] memory) external;
    function removeToken(uint256, uint256) external;
    function setOwnerAcct(address) external;
    function setOwnerOper(address) external;
    function setClientAcct(uint256, address) external;
    function setClientOper(uint256, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBavePayV1Factory {
    event FactoryOperChanged(address indexed oldAddress, address indexed newAddress);
    event UnionCreated(uint256 unionId, address indexed union);

    function factoryOper() external view returns (address);
    function allUnions(uint256) external view returns (address union);

    function allUnionsLength() external view returns (uint256);
    function createUnion(address ownerAcct, address ownerOper)
        external
        returns (address union);
    function setFactoryOper(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'sub-underflow');
    }
}