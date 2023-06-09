// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./TransferHelper.sol";
import "./Address.sol";
import "./SafeMath.sol";


contract Polyzkp is Ownable {
    using SafeMath for uint256;

    address public walletFee;
    address public walletWithdraw;
    address public walletNode;
    address public walletTicket;
    address public walletPledge;

    uint public fee;
    uint private pointMax = 10 ** 8;

    // 签名验证地址
	address private signer;

    // 禁用的证明
	mapping(bytes => bool) expired;



    event Setting(
        address walletFee,
        address walletWithdraw,
        address walletNode,
        address walletTicket,
        address walletPledge,
        uint fee
    );

    event Entry(
        uint pid,
        uint[] field,
        address player,
        uint signType,
        address token,
        uint amount,
        uint time,
		bytes signature
    );

    event Expend(
        address player,
        address token,
        uint amount,
        uint fee,
        uint time,
		bytes signature
    );

    constructor(
        address _walletFee,
        address _walletWithdraw,
        address _walletNode,
        address _walletTicket,
        address _walletPledge,
        address _signer,
        uint _fee
    ) {
        _verifySign(_signer);
        _setting(_walletFee,_walletWithdraw,_walletNode,_walletTicket,_walletPledge,_fee);
    }

    receive() external payable {}
    fallback() external payable {}


    function hashMsg(
        uint signType,
		address token,
		uint amount,
		uint deadline
	) internal view returns (bytes32 msghash) {
		return	keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(block.chainid,signType,msg.sender,token,amount,deadline))
            )
        );
	}



    


    function _trust(
        uint signType,
		address token,
		uint amount,
		uint deadline,
        bytes memory signature
    ) private {
        require(!expired[signature],"Polyzkp::certificate expired");
        address prove = ECDSA.recover(hashMsg(signType,token,amount,deadline), signature);
        require(signer == prove,"Polyzkp::invalid certificate");	
        expired[signature] = true;
    }

    function _receive(
        uint signType,
        address token,
		uint amount
    ) private {
        address to;
        if(signType == 1) {
            // 节点入金
            to = walletNode;
        }else if(signType == 2) {
            // 门票入金
            to = walletTicket;
        }else if(signType == 3) {
            // 质押入金
            to = walletPledge;
        }
        if(token == address(0)) {
			require(msg.value == amount,"Polyzkp::input eth is not accurate");
            Address.sendValue(payable(to),msg.value);
		}else {
            TransferHelper.safeTransferFrom(token,msg.sender,to,amount);
		}
    }

    
    function Invest(
        uint pid,
        uint[] memory field,
        uint signType,
        address token,
        uint amount,
        uint deadline,
		bytes memory signature
    ) public payable {
        _trust(signType,token,amount,deadline,signature);
        _receive(signType,token,amount);

        emit Entry(pid,field,msg.sender,signType,token,amount,block.timestamp,signature);
    }

    function _expend(
        address token,
        uint amount,
        bytes memory signature
    ) private {
        uint realAmount = pointMax.sub(fee).mul(amount).div(pointMax);
        uint feeAmount = amount.sub(realAmount);

        if(token == address(0)) {
            Address.sendValue(payable(msg.sender),realAmount);
            Address.sendValue(payable(walletFee),feeAmount);
		}else {
            TransferHelper.safeTransferFrom(token,walletWithdraw,msg.sender,realAmount);
            TransferHelper.safeTransferFrom(token,walletWithdraw,walletFee,feeAmount);
		}

        emit Expend(msg.sender,token,amount,feeAmount,block.timestamp,signature);
    }

    function Withdrawal(
        address token,
        uint amount,
        uint deadline,
		bytes memory signature
    ) public {
        _trust(4,token,amount,deadline,signature);
        _expend(token,amount,signature);
    }

    

    function setting(
        address _walletFee,
        address _walletWithdraw,
        address _walletNode,
        address _walletTicket,
        address _walletPledge,
        uint _fee
    ) public onlyOwner {
        _setting(_walletFee,_walletWithdraw,_walletNode,_walletTicket,_walletPledge,_fee);
    }

    function _setting(
        address _walletFee,
        address _walletWithdraw,
        address _walletNode,
        address _walletTicket,
        address _walletPledge,
        uint _fee
    ) private {
        walletFee = _walletFee;
        walletWithdraw = _walletWithdraw;
        walletNode = _walletNode;
        walletTicket = _walletTicket;
        walletPledge = _walletPledge;
        fee = _fee;

        emit Setting(walletFee,walletWithdraw,walletNode,walletTicket,walletPledge,fee);
    }

    function verifySign(
		address _signer
	) public onlyOwner {
		_verifySign(_signer);
	}

	function _verifySign(
		address _signer
	) private {
		require(_signer != address(0),"Polyzkp::invalid signing address");
		signer = _signer;
	}
}