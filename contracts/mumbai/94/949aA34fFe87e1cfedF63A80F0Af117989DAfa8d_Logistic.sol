// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Logistic {
  constructor() {}

  /* ===================================================== VARIABLES ==================================================== */
  mapping(string => uint256) private s_orderIdToManifestId;
  mapping(uint256 => Event[]) private s_manifestEvents;
  uint256 private s_lastManifestId = 1;

  /* ======================================================= STRUCTS ====================================================== */
  struct Event {
    OrderStatusType orderStatus;
    uint256 timestamp;
    string location;
    string orderId;
  }

  enum OrderStatusType {
    SHIPPED,
    DELIVERED
  }

  /* ======================================================= EVENTS ===================================================== */

  /* ================================================= MUTATIVE FUNCTIONS =============================================== */
  function createOrders(
    string[] memory _ordersIds,
    string memory _sourceAddress
  ) external {
    for (uint256 i = 0; i < _ordersIds.length; i++) {
      require(
        s_orderIdToManifestId[_ordersIds[i]] == 0,
        "The order was already created"
      );
      s_orderIdToManifestId[_ordersIds[i]] = s_lastManifestId;
    }
    Event memory _event;
    _event.orderStatus = OrderStatusType.SHIPPED;
    _event.timestamp = block.timestamp;
    _event.orderId = "";
    _event.location = _sourceAddress;
    s_manifestEvents[s_lastManifestId].push(_event);
    s_lastManifestId++;
  }

  function deliverOrder(
    string memory _orderId,
    string memory _location
  ) external {
    uint256 manifestId = s_orderIdToManifestId[_orderId];
    require(manifestId != 0, "The order was not created");

    for (uint256 i = 0; i < s_manifestEvents[manifestId].length; i++) {
      Event memory eventCreated = s_manifestEvents[manifestId][i];
      if (
        keccak256(abi.encodePacked(eventCreated.orderId)) ==
        keccak256(abi.encodePacked(_orderId))
      ) {
        require(
          s_manifestEvents[manifestId][i].orderStatus !=
            OrderStatusType.DELIVERED,
          "The order was already delivered"
        );
      }
    }
    Event memory _event;
    _event.orderStatus = OrderStatusType.DELIVERED;
    _event.timestamp = block.timestamp;
    _event.orderId = _orderId;
    _event.location = _location;
    s_manifestEvents[manifestId].push(_event);
  }

  /* ======================================================== VIEWS ===================================================== */

  function getOrder(
    string memory _orderId
  ) external view returns (uint256, Event[] memory) {
    uint256 _manifestId = s_orderIdToManifestId[_orderId];
    require(_manifestId != 0, "The order was not created");
    uint256 size;
    for (uint256 i = 0; i < s_manifestEvents[_manifestId].length; i++) {
      size = i + 1;
      if (
        keccak256(abi.encodePacked(s_manifestEvents[_manifestId][i].orderId)) ==
        keccak256(abi.encodePacked(_orderId))
      ) {
        break;
      }
    }

    Event[] memory _eventsOfOrder = new Event[](size);
    for (uint256 i = 0; i < size; i++) {
      _eventsOfOrder[i] = s_manifestEvents[_manifestId][i];
    }
    return (_manifestId, _eventsOfOrder);
  }
}