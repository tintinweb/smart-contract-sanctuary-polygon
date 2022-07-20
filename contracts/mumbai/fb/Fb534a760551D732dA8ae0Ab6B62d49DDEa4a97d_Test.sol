// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Test{
   
mapping(address => bytes32[]) public OrderbyAddress;
mapping(address => uint256) public orderNumber;
bytes32[] public allOrderIds;
uint256 public allNumberOrderIds;

function CreateP2POrderPolygon()external {
          bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender
            )
        );

        allOrderIds.push(orderId);
        OrderbyAddress[msg.sender].push(orderId);

        allNumberOrderIds += 1;
        orderNumber[msg.sender] += 1;
    }


function cancelOrderPolygon(bytes32 _orderId) external {
		
         delete allOrderIds[findIndexAllOrder(_orderId)];
		// remove(_orderId,msg.sender);
        delete OrderbyAddress[msg.sender][findIndexOrder(_orderId,msg.sender)];
		
         orderNumber[msg.sender] -= 1;
         allNumberOrderIds -= 1;
    }

function getOrderIdByAddress(address _address) external view returns (bytes32[] memory)
    {   
        require (orderNumber[_address] != 0, "Order not found.");
        uint256 _lengthId = orderNumber[_address];
        _lengthId -= 1;
        bytes32[] memory orders = new bytes32[](_lengthId + 1);
        for (uint256 id = 0; id <= _lengthId; id++) {
            orders[id] = OrderbyAddress[_address][id];
        }
        return orders;
    }

function getAllOrderId() external view returns (bytes32[] memory)
    {   
        require (allNumberOrderIds != 0, "Order not found.");
        uint256 _lengthId = allNumberOrderIds;
        _lengthId -= 1;
        bytes32[] memory orders = new bytes32[](_lengthId + 1);
        for (uint256 id = 0; id <= _lengthId; id++) {
            orders[id] = allOrderIds[id];
        }
        return orders;
    }
function findIndexOrder(bytes32 _orderId, address _walletAddress) public view returns (uint256){
        for (uint256 i; i < OrderbyAddress[_walletAddress].length; i++) {
            if (OrderbyAddress[_walletAddress][i] == _orderId) {
                return i;
            }
        }

        revert(
            "[MarketplaceNFT.findIndex] Can't find the ownership of this NFT."
        );
    }

function findIndexAllOrder(bytes32 _orderId) public view returns (uint256){
        for (uint256 i; i < allOrderIds.length; i++) {
            if (allOrderIds[i] == _orderId) {
                return i;
            }
        }
        revert(
            "[MarketplaceNFT.findIndex] Can't find the ownership of this NFT."
        );
    }
function remove(bytes32 _orderId, address _walletAddress) private {
        uint256 index = findIndexOrder(_orderId, _walletAddress);
        OrderbyAddress[_walletAddress][index] = OrderbyAddress[_walletAddress][
            OrderbyAddress[_walletAddress].length - 1
        ];
        OrderbyAddress[_walletAddress].pop();
    }

}