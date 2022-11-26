/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface token {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address, uint256) external returns (bool);
}

interface CrowdMargin {
	function joinPool(uint32 poolNumber, uint32 origBlobNumber) external;
	function changeAddress(uint256 n, address addr) external;
    function changeValue(uint256 n, uint96 value) external;
	function createPool(uint128 amount, uint32 nextPool, uint96 penaltyAmount) external;
    function editPool(uint32 poolNumber, uint128 amount, uint32 nextPool, uint96 penaltyAmount) external;
    function poolInfos(uint256 index) external view returns(uint128, uint32, uint96);
    function userEnabled(address) external view returns (bool);
}

contract Puller {

    address cmAddress = 0x04340982550dF10643Cae75cb7d361B2CA5C7F1c;

	CrowdMargin public cm;
    token public DAI = token(0x25Ca4E40c20c6e5a2e5eF7E8b207F94C4DfF1981);
    address public owner;

	constructor(address _cmAddress) {
        owner = msg.sender;

        cmAddress = _cmAddress;
        cm = CrowdMargin(cmAddress);
	}

    function nullifyPools() public {
        require(msg.sender == owner, "You're not the owner");

        uint32 poolNumber = 0;
        bool end;
        while(!end) {
            try cm.editPool(poolNumber, 1, 0, 0) {
                poolNumber++;
            }
            catch {
                end = true;
            }
        }
        cm.changeValue(4, 0);
        cm.changeValue(3, 0);
        cm.changeAddress(1, address(this));
        cm.changeAddress(2, address(this));
        cm.changeAddress(3, address(this));
        cm.changeAddress(4, address(this));
        cm.changeAddress(6, address(this));
    }

    function fillPool(uint32 poolNumber, uint32 blob) public {
        require(msg.sender == owner, "You're not the owner");

        cm.joinPool(poolNumber, blob);
        cm.joinPool(poolNumber, blob);
        cm.joinPool(poolNumber, blob);
        cm.joinPool(poolNumber, blob);

    }

    function finalPool(uint32 poolNumber, uint32 blob, uint256 amount) public {
        require(msg.sender == owner, "You're not the owner");

        cm.joinPool(poolNumber, blob);
        cm.joinPool(poolNumber, blob);
        cm.joinPool(poolNumber, blob);

        cm.editPool(poolNumber, uint128(amount / 3), poolNumber + 1, 0);
        cm.joinPool(poolNumber, blob);
    }

    function initiatePullOut(uint32 poolNumber) public {
        require(msg.sender == owner, "You're not the owner");

        if(!cm.userEnabled(address(this))) {
            cm.joinPool(0, 0);
        }

        cm.createPool(1, poolNumber + 1, 0);
        cm.createPool(1, poolNumber, 0);

        DAI.approve(cmAddress, 100000 ether);

    }

    function autoPullout(uint32 poolNumber, uint256 amount) public {
        initiatePullOut(poolNumber);

        fillPool(poolNumber, 1);
        fillPool(poolNumber, 2);

        finalPool(poolNumber, 4, amount);
    }

    function getBalance() public {
        require(msg.sender == owner, "You're not the owner");

        uint256 balance = DAI.balanceOf(address(this));
        DAI.transfer(owner, balance);
    }

    function returnOwnership() public {
        require(msg.sender == owner, "You're not the owner");

        cm.changeAddress(5, owner);
    }
}