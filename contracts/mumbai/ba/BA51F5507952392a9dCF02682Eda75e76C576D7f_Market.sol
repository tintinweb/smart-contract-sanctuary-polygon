pragma solidity ^0.8.5;

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Court {

	uint256 public constant DISPUTE_EXPIRY = 7 days;

	address public marketAddress;
	address public marketOwner;

	mapping(address => bool) public juries;
	mapping(uint256 => address) public juriesByIndex;
	mapping(address => uint256) public indexByJury;

	struct Votes {
		uint256 countVotesFor;
		uint256 countVotesAgainst;
		uint256[] juryVotes; // 0 - for, 1 - against
	}

	enum DisputePeriod {
		EvidenceSubmission,
		Voting,
		Execution,
		Settled
	}

	struct Dispute {
		uint256 id;
		uint256 raisedAt;
		uint256 amount;
		address raisedBy;
		address raisedAgainst;
		Votes votes;
		DisputePeriod period;
		string[] dealerEvidenceURIs;
		string[] opponentEvidenceURIs;
	}

	uint256 public disputesCount;

	mapping(uint256 => mapping(uint256 => Dispute)) public dealDisputes;

	event DisputeRaised(
		uint256 dealId,
		address raisedBy,
		address raisedAgainst
	);

	event EvidenceSubmitted(
		uint256 dealId,
		uint256 dipsuteId,
		string[] evidenceURIs
	);

	event VoteCasted(
		address jury,
		uint256 vote,
		uint256 dealId,
		uint256 dipsuteId
	);

	event DisputeSettled(uint256 dealId, uint256 dipsuteId);

	constructor(address _marketAddress, address _marketOwner, address[] memory _juries) {
		marketAddress = _marketAddress;
		marketOwner = _marketOwner;
		for(uint256 i=0; i<_juries.length; i++) {
			juries[_juries[i]] = true;
			juriesByIndex[i] = _juries[i];
			indexByJury[_juries[i]] = i;
		}
	}

	function createDispute(uint256 dealId, address raisedBy, address raisedAgainst, uint256 amount) external {
		require(msg.sender == marketAddress, "Can only be invoked by market contract");
		Dispute memory dispute;
		dispute.id = disputesCount;
		dispute.raisedBy = raisedBy;
		dispute.raisedAgainst = raisedAgainst;
		dispute.raisedAt = block.timestamp;
		dispute.amount = amount;

		dealDisputes[dealId][disputesCount] = dispute;
		disputesCount++;

		emit DisputeRaised(
			dealId,
			raisedBy,
			raisedAgainst
		);
	}

	function submitEvidences(uint256 dealId, uint256 dipsuteId, string[] memory evidenceURIs) external {
		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.EvidenceSubmission, "Evidence submission period is over");

		if (msg.sender == dispute.raisedBy) {
			require(dispute.dealerEvidenceURIs.length + evidenceURIs.length <= 10, "Evidence limit reached");
			for(uint256 i=0; i<evidenceURIs.length; i++) {
				dispute.dealerEvidenceURIs.push(evidenceURIs[i]);
			}
		} else if (msg.sender == dispute.raisedAgainst) {
			require(dispute.opponentEvidenceURIs.length + evidenceURIs.length <= 10, "Evidence limit reached");
			for(uint256 i=0; i<evidenceURIs.length; i++) {
				dispute.opponentEvidenceURIs.push(evidenceURIs[i]);
			}
		} else {
			revert("Not authorised to submit evidence");
		}

		if (dispute.dealerEvidenceURIs.length > 0 && dispute.opponentEvidenceURIs.length > 0) {
			// move to voting
			dispute.period = DisputePeriod.Voting;
		}

		emit EvidenceSubmitted(dealId, dipsuteId, evidenceURIs);
	}

	function _completeVotingPeriod(Dispute memory _dispute) private returns (Dispute memory) {
		if (_dispute.raisedAt + 7 days <= block.timestamp) {
			_dispute.period = DisputePeriod.Execution;
		}

		return _dispute;
	}

	function castVote(uint256 vote, uint256 dealId, uint256 dipsuteId) external {
		require(juries[msg.sender], "Not authorised to vote");
		// add check for only the specific juror is allowed to vote who is picked randomly

		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.Voting, "Cannot vote, period over");

		if (dispute.raisedAt + DISPUTE_EXPIRY <= block.timestamp) {
			dispute.period = DisputePeriod.Execution;
			return;
		}

		if (vote == 0) {
			dispute.votes.countVotesFor += 1;
		} else if (vote == 1) {
			dispute.votes.countVotesAgainst += 1;
		} else {
			revert("Invalid vote option");
		}

		dispute.votes.juryVotes[indexByJury[msg.sender]] = vote;

		emit VoteCasted(msg.sender, vote, dealId, dipsuteId);
	}



	function requestSettlement(uint256 dealId, uint256 dipsuteId) external {
		Dispute storage dispute = dealDisputes[dealId][dipsuteId];
		require(dispute.period == DisputePeriod.Execution, "Dispute in non-execution period");

		IERC20 market = IERC20(marketAddress);
		if (dispute.votes.countVotesFor >= dispute.votes.countVotesAgainst) {
			market.transfer(dispute.raisedBy, dispute.amount);
		} else {
			market.transfer(dispute.raisedAgainst, dispute.amount);
		}

		dispute.period = DisputePeriod.Settled;

		emit DisputeSettled(dealId, dipsuteId);
	}
}

pragma solidity ^0.8.5;

import { Court } from './Court.sol';

contract CourtFactory {
	mapping(address => address) public marketCourts;

	event CourtCreated(address courtAddress, address marketAddress, address marketOwner, address[] juries);

	function createCourt(address _marketAddress, address _marketOwner, address[] memory _juries) external returns(address) {
		Court court = new Court(_marketAddress, _marketOwner, _juries);
		marketCourts[_marketAddress] = address(court);
		emit CourtCreated(address(court), _marketAddress, _marketOwner, _juries);
		return address(court);
	}
}

pragma solidity ^0.8.5;

import { CourtFactory } from "./CourtFactory.sol";
import { Court } from "./Court.sol";

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Market {
	string  public name;
	string  public description;

	enum DealStatus {
		Active,
		Disabled // cannot be disabled if an order is active for the deal
	}

	struct Deal {
		uint256 id;
		uint256 pricePerUnit;
		uint256 minLimitAmount;
		uint256 maxLimitAmount;
	  	uint256 availableAmount;
		uint256 expiryTime;
		DealStatus status;
		address dealerAddress;
		string dealerName;
		string[] paymentMethods;
		string[] paymentDetails;
	}

	mapping(uint256 => Deal) public deals;

	enum OrderStatus {
		Created, // can only create if deal is active
		DealerAccepted,
		UserTransactionDone,
		Settled,
		InDispute,
		Expired,
		Cancelled
	}

	struct Order {
		uint256 id;
		uint256 dealId;
 		uint256 dealPrice;
		uint256 amount;
		uint256 startedAt;
		uint256 settledAt;
		OrderStatus status;
	  	address userAddress;
	}

	mapping(uint256 => Order) public orders;
	mapping(address => uint256[]) public dealerOrders;
	mapping(address => uint256[]) public userOrders;

	address public courtAddress;
	address public marketOwner;
	IERC20 erc20;

	uint256 public dealsCount;
	uint256 public ordersCount;

	event DealCreated(
		string dealName,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		uint256 availableAmount,
		string[] paymentMethods,
		string[] paymentDetails,
		uint256 expiryTime
	);

	event DealUpdated(
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		string[] paymentMethods,
		string[] paymentDetails,
		uint256 expiryTime
	);

	event OrderCreated(
		uint256 orderId,
		address userAddress,
		address dealerAddress,
		uint256 dealPrice,
		uint256 amount
	);

	event OrderUpdated(
		uint256 orderId,
		uint256 amount
	);

	event DealAmountIncreased(
		uint256 dealId,
		uint256 amount
	);

	event OrderCancelled(uint256 orderId);

	event OrderAccepted(uint256 orderId);

	event OrderDoneByUser(uint256 orderId);

	event OrderSettled(uint256 orderId);

	event CourtUpdated(address courtAddress);

	event DisputeRaised(uint256 dealId, address raisedBy, address raisedAgainst, uint256 amount);

	constructor(string memory _name, string memory _description, address _erc20Address, address[] memory _juries, address courtFactory) {
		name = _name;
		description = _description;
		erc20 = IERC20(_erc20Address);
		marketOwner = msg.sender;

		_setupCourt(address(this), msg.sender, _juries, courtFactory);
	}

	function _setupCourt(address _marketAddress, address _marketOwner, address[] memory _juries, address courtFactory) private {
		CourtFactory _courtFactory = CourtFactory(courtFactory);
		courtAddress = _courtFactory.createCourt(_marketAddress, _marketOwner, _juries);
	}

	function createDeal(
		string memory dealerName,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		uint256 availableAmount,
		string[] memory paymentMethods,
		string[] memory paymentDetails,
		uint256 expiryTime
	) external {
		require(paymentMethods.length == paymentDetails.length, "Payment arguments invalid");

		Deal memory existingDeal = deals[dealsCount];
		require(existingDeal.availableAmount == 0, "You are already a dealer");

		bool success = erc20.transferFrom(msg.sender, address(this), availableAmount);
	  	if (!success) {
	  		return;
	  	}
	  	
	  	Deal memory deal;
	  	deal.id = dealsCount;
	  	deal.dealerName = dealerName;
	  	deal.dealerAddress = msg.sender;
	  	deal.pricePerUnit = pricePerUnit;
	  	deal.minLimitAmount = minLimitAmount;
	  	deal.maxLimitAmount = maxLimitAmount;
	  	deal.availableAmount = availableAmount;
	  	deal.paymentMethods = paymentMethods;
	  	deal.paymentDetails = paymentDetails;
	  	deal.expiryTime = expiryTime;

	  	dealsCount++;

	  	deals[deal.id] = deal;

	  	emit DealCreated(
	  		dealerName,
	  		pricePerUnit,
	  		minLimitAmount,
	  		maxLimitAmount,
	  		availableAmount,
	  		paymentMethods,
	  		paymentDetails,
	  		expiryTime
  		);
	}

	function updateDeal(
		uint256 dealId,
		uint256 pricePerUnit,
		uint256 minLimitAmount,
		uint256 maxLimitAmount,
		string[] memory paymentMethods,
		string[] memory paymentDetails,
		uint256 expiryTime
	) external {
		Deal storage dealerDeal = deals[dealId];
		require(dealerDeal.dealerAddress == msg.sender, "Not authorised to update deal");
		require(dealerDeal.availableAmount != 0, "Deal not active");
		require(dealerDeal.status == DealStatus.Active, "Deal not active");

		dealerDeal.minLimitAmount = minLimitAmount;
		dealerDeal.maxLimitAmount = maxLimitAmount;
		dealerDeal.paymentMethods = paymentMethods;
		dealerDeal.paymentDetails = paymentDetails;
		dealerDeal.expiryTime = expiryTime;

		emit DealUpdated(
			pricePerUnit,
			minLimitAmount,
			maxLimitAmount,
			paymentMethods,
			paymentDetails,
			expiryTime
		);
	}

	function createOrder(
		uint256 dealId,
		uint256 amount
	) external {
		Deal storage deal = deals[dealId];
		require(deal.status == DealStatus.Active, "Deal not active");
		require(deal.availableAmount > amount, "Sufficient amount not available with dealer");

		Order storage order = orders[ordersCount];
		order.id = ordersCount;
		order.dealId = deal.id;
		order.userAddress = msg.sender;
		order.dealPrice = deal.pricePerUnit;
		order.amount = amount;
		order.startedAt = block.timestamp;

		orders[ordersCount] = order;
		dealerOrders[deal.dealerAddress].push(ordersCount);
		userOrders[msg.sender].push(ordersCount);

		emit OrderCreated(
			ordersCount,
			msg.sender,
			deal.dealerAddress,
			order.dealPrice,
			amount
		);

		ordersCount++;
	}

	function updateOrder(
		uint256 orderId,
		uint256 amount
	) external {
		Order storage order = orders[orderId];
		require(order.userAddress == msg.sender, "Not authorised to update order");
		require(order.status == OrderStatus.Created, "Cannot update order once its accepted by dealer");

		Deal storage deal = deals[order.dealId];

		uint256 avlblAmount = deal.availableAmount;
		avlblAmount += order.amount;
		require(avlblAmount >= amount, "Sufficient amount not available with dealer");

		order.amount = amount;
		deal.availableAmount = avlblAmount - amount;

		emit OrderUpdated(
			orderId,
			amount
		);
	}

	function cancelOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(order.userAddress == msg.sender, "Not authorised to update order");
		require(order.status == OrderStatus.Created, "Cannot update order once its accepted by dealer");

		Deal storage deal = deals[order.dealId];
		deal.availableAmount = deal.availableAmount + order.amount;
		order.status = OrderStatus.Cancelled;

		emit OrderCancelled(orderId);
	}

	function increaseDealAmount(uint256 dealId, uint256 amount) external {
		Deal storage dealerDeal = deals[dealId];
		require(dealerDeal.status == DealStatus.Active, "Deal not active");

		bool success = erc20.transferFrom(msg.sender, address(this), amount);
	  	if (!success) {
	  		return;
	  	}

	  	dealerDeal.availableAmount += amount;

	  	emit DealAmountIncreased(dealId, amount);
	}

	function acceptOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		Deal storage deal = deals[order.dealId];
		require(msg.sender == deal.dealerAddress, "Not authorised to accept order");
		require(order.status == OrderStatus.Created, "Order status should be created in order to accept");

		deal.availableAmount -= order.amount;
		order.status = OrderStatus.DealerAccepted;

		emit OrderAccepted(orderId);
	}

	function txDoneByUser(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(msg.sender == order.userAddress, "Not authorised to mark order as done");
		require(order.status == OrderStatus.DealerAccepted, "Order status should be accepted by dealer in order to initiate");

		order.status = OrderStatus.UserTransactionDone;

		emit OrderDoneByUser(orderId);
	}

	function settleOrder(uint256 orderId) external {
		Order storage order = orders[orderId];
		require(msg.sender == order.userAddress, "Not authorised to mark order as done");
		require(order.status == OrderStatus.DealerAccepted, "Order status should be accepted by dealer in order to initiate");

		bool success = erc20.transfer(msg.sender, order.amount);
	  	if (!success) {
	  		return;
	  	}

		order.status = OrderStatus.Settled;

		emit OrderSettled(orderId);
	}

	function updateCourt(address _courtAddress) external {
		require(msg.sender == marketOwner, "Not authorised to update court");
		courtAddress = _courtAddress;

		emit CourtUpdated(_courtAddress);
	}

	function raiseDispute(uint256 orderId) external {
		require(courtAddress != address(0), "Court not found");
		Order storage order = orders[orderId];
		Deal storage deal = deals[order.dealId];
		require(msg.sender == deal.dealerAddress, "Not authorised to raise dispute");
		require(order.status == OrderStatus.UserTransactionDone, "Order status should be tx done by user in order to raise dispute");

		order.status = OrderStatus.InDispute;


		// raise dispute on court
		Court _court = Court(courtAddress);
		_court.createDispute(order.dealId, msg.sender, order.userAddress, order.amount);

		emit DisputeRaised(order.dealId, msg.sender, order.userAddress, order.amount);
	}
}