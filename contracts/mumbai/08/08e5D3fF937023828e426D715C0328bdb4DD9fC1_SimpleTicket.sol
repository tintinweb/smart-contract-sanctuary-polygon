/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

contract SimpleTicket {

    //Ticket owner address
    address owner;

    //Ticket price 
    uint256 ticketPrice = 0.01 ether;

    //mapping for ticket Holders
    mapping(address => uint256) ticketHolders;

    constructor() {
        owner = msg.sender;
    }

    //Function for buying tickets by giving user address and ticket amount in parameters

    function buyTickets(address _user, uint256 _amount) public payable {
        require(
            msg.value >= ticketPrice * _amount,
            "You dont have sufficient amount"
        );
        addTicket(_user, _amount);
    }

    //Function for use the ticket by giving user address and amount in parameters

    function useTickets(address _user, uint256 _amount) public {
        subTicket(_user, _amount);
    }

    //Function for adding tickets by giving user address and amount in parameters (this is internal function only owner can add new tickets)

    function addTicket(address _user, uint256 _amount) internal {
        ticketHolders[_user] = ticketHolders[_user] + _amount;
    }

    //Function for subtracting tickets by giving user address and amount in parameters (this is internal function only owner can subtract sold tickets)

    function subTicket(address _user, uint256 _amount) internal {
        require(ticketHolders[_user] >= _amount, "You dont have tickets");
        ticketHolders[_user] = ticketHolders[_user] - _amount;
    }

    
    //Function for withdraw amount (only owner of the contract can call this function) 

    function withdraw() public {
        require(msg.sender == owner, "you are Not the owner");
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}