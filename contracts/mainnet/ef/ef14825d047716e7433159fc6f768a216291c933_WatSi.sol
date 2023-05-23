/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: watpalav1.sol


pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


//import "@openzeppelin/contracts/access/Ownable.sol";

contract WatSi{
    address public creator;
    constructor(){
       creator = msg.sender;
    }
    IERC20 public decent;
    address public Admin1;
    address public Admin2;
    address public Decentpoint;
    address public WatAddr;  
    uint public NumEvent = 0;
    uint public NumJudge = 0;
    uint public SystemFee_Withdrawable;


    function setRoler(address _admin1, address _admin2, address _decentpoint, address _watadd)public  OnlyRightAddress{
      Admin1 = _admin1;
      Admin2 = _admin2;      
     decent = IERC20(_decentpoint);
     WatAddr = _watadd;

    }

     modifier OnlyRightAddress {
        require((msg.sender == creator)||(msg.sender == Admin2)||(msg.sender==Admin1));
        _;
    }  


       uint public SystemFee; uint public JudgeFee;
    
    function SetFee(uint _systemFee, uint _judgeFee)public OnlyRightAddress{
       SystemFee = _systemFee; JudgeFee = _judgeFee;
    }

   

    mapping(address=>uint) judgeAble; //0 = no, 1= Assigned to judge
    mapping(address => uint) JudgeID;
    mapping(address => uint) Match_judge;
    mapping(address => uint) AccPlaced;
    mapping(uint => address) AddrOfJudgeID;

   // Admin assign judge
    function AssignJudge(address _judge)public OnlyRightAddress{
      judgeAble[_judge]=1;
      JudgeID[_judge]=NumJudge;
      AddrOfJudgeID[NumJudge]=_judge;
       NumJudge++;
       Logs.push(Log(NumLogs,block.timestamp, msg.sender, 3, 0,0,0,_judge ));
       NumLogs++;
    }



    function DeAssignJudge(address _judge)public OnlyRightAddress{
        judgeAble[_judge]=0;
        Logs.push(Log(NumLogs,block.timestamp, msg.sender, 4, 0,0,0,_judge ));
       NumLogs++;
    }
  
  // view judge  details and returns judgeID, address, match judged, accumulated point to judge, status
  function viewJudge(uint i)public view returns(uint,address,uint,uint, uint){
    return(i, AddrOfJudgeID[i],Match_judge[AddrOfJudgeID[i]],
    AccPlaced[AddrOfJudgeID[i]],judgeAble[AddrOfJudgeID[i]]);
  }


   mapping(uint=>address) Setter;
   mapping(uint=>uint) TimeStart;
   mapping(uint=>uint) TimeEnd;
   mapping(uint=>uint)  A_side_accumalted;
   mapping(uint=>uint)  B_side_accumalted;
   mapping(uint=>uint)  A_remain;
   mapping(uint=>uint)  A_Last_rank_mathched;   
   mapping(uint=>uint)  B_remain;
   mapping(uint=>uint)  B_Last_rank_mathched;
   mapping(uint=>uint)  sum_accumalted;
   mapping(uint=>uint)  numA;
   mapping(uint=>uint)  numB;
    mapping(uint=>uint)  AmountJoin;
   mapping(uint=>uint)  status;  // 0 = ended, 1 = openning, 3 = A win, 4 = B win
   

  mapping(address=>mapping(uint => bool)) EventClaimed; //false= not claimed, true = claimed



//action code;   1 setup event, 2 placepoint, 3 assign, 4 deassign, 5 justify, 6 claim reward

struct Log{
    uint ID;
    uint Time;
    address who;
    uint   actions;
    uint side; 
    uint amount;
    uint eventID;
    address objective;    
}
uint public NumLogs;
Log[] public Logs;

function viewLogs(uint _id)public view returns(uint,address,uint,uint,uint,uint,address){
    return(Logs[_id].Time, Logs[_id].who, Logs[_id].actions, Logs[_id].side,
    Logs[_id].amount,Logs[_id].eventID,Logs[_id].objective );
}


mapping(uint=>mapping(uint => address)) AddrOfJoiner;   
mapping(address=>mapping(uint => uint)) RankOfJoiner;
mapping(address=>mapping(uint => uint)) SideOfJoiner;
mapping(address=>mapping(uint => uint)) A_RankOfJoiner;
mapping(address=>mapping(uint => uint)) B_RankOfJoiner;
mapping(address=>mapping(uint => uint)) AmountOfJoiner;
mapping(address=>mapping(uint => uint)) PlaceTimeOfJoiner;
mapping(address=>mapping(uint => uint)) A_Sum_Place_At_Join;
mapping(address=>mapping(uint => uint)) B_Sum_Place_At_Join;


   //anyone can set up fight event
   function SetEvent(uint _placedPoint, uint _side, uint _timeStart,uint _timeEnd)public returns(uint){
     
       require(_timeEnd> _timeStart);
       uint _Point = _placedPoint*10**18;

       //approve(address(this),_Point); make approving first!!
       decent.transferFrom(msg.sender,address(this),_Point);

       if (_side == 3){
            A_side_accumalted[NumEvent] = _Point;
             numA[NumEvent] = 1;
             A_remain[NumEvent]=_Point;
             A_RankOfJoiner[msg.sender][NumEvent]=1;
             A_Sum_Place_At_Join[msg.sender][NumEvent]=_Point;

       }

       if (_side == 4){
            B_side_accumalted[NumEvent] = _Point;
             numB[NumEvent] = 1;
             B_remain[NumEvent]=_Point;
             B_RankOfJoiner[msg.sender][NumEvent]=1;
             B_Sum_Place_At_Join[msg.sender][NumEvent]=_Point;
       }
       
      Setter[NumEvent]=msg.sender; TimeStart[NumEvent]=_timeStart;
      TimeEnd[NumEvent]=_timeEnd; status[NumEvent]=1; AmountJoin[NumEvent]+=1; 
      sum_accumalted[NumEvent]+=_Point;  
     
      RankOfJoiner[msg.sender][NumEvent]=1;
      AddrOfJoiner[1][NumEvent]=msg.sender;
      SideOfJoiner[msg.sender][NumEvent]= _side;
      AmountOfJoiner[msg.sender][NumEvent]=_Point;
      PlaceTimeOfJoiner[msg.sender][NumEvent]=block.timestamp;

      Logs.push(Log(NumEvent,PlaceTimeOfJoiner[msg.sender][NumEvent], msg.sender, 1, _side,_placedPoint,NumEvent,WatAddr ));
      NumEvent++;NumLogs++;
      return Logs.length-1;
   }

// 
     function JoinEvent(uint _fightEvent, uint _side, uint _PlacePoint)public returns(uint){
        uint placetime = block.timestamp;
        require(TimeEnd[_fightEvent]>= placetime);
        
      
        require(SideOfJoiner[msg.sender][_fightEvent]==0);  


        uint _place = _PlacePoint*10**18;
       //approve(address(this),_place);
       decent.transferFrom(msg.sender,address(this),_place);
       
        

       //joiner.push(Joiner(_fightEvent, msg.sender, _side, _place, placetime ));
       AmountJoin[_fightEvent]+=1; sum_accumalted[_fightEvent]+=_place;

       if (_side == 3){
            A_side_accumalted[_fightEvent] += _place;
            A_Sum_Place_At_Join[msg.sender][_fightEvent]=A_side_accumalted[_fightEvent];           
             
             if(numA[_fightEvent]<1){
             A_RankOfJoiner[msg.sender][_fightEvent] =1;
            }else{
                numA[_fightEvent] += 1;
                A_RankOfJoiner[msg.sender][_fightEvent] =numA[_fightEvent];
            }             
           A_remain[_fightEvent] +=_place;
             
       }

       if (_side == 4){
            B_side_accumalted[_fightEvent] += _place;
            B_Sum_Place_At_Join[msg.sender][_fightEvent]=B_side_accumalted[_fightEvent];    
            
            B_RankOfJoiner[msg.sender][_fightEvent] +=1;
            if(numB[_fightEvent]<1){
             B_RankOfJoiner[msg.sender][_fightEvent] =1;
            }else{
                numB[_fightEvent] += 1;
                B_RankOfJoiner[msg.sender][_fightEvent] =numB[_fightEvent];
            }
          B_remain[_fightEvent] +=_place;
       }

       if(A_remain[_fightEvent]<B_remain[_fightEvent]){
               A_remain[_fightEvent]=0;
               B_remain[_fightEvent]-=A_remain[_fightEvent];
               A_Last_rank_mathched[_fightEvent]=numA[_fightEvent];
           }

       if(A_remain[_fightEvent]>B_remain[_fightEvent]){
               B_remain[_fightEvent]=0;
               A_remain[_fightEvent]-=B_remain[_fightEvent];
               B_Last_rank_mathched[_fightEvent]=numB[_fightEvent];
           }    

       if(A_remain[_fightEvent]==B_remain[_fightEvent]){
               B_remain[_fightEvent]=0;
               A_remain[_fightEvent]=0;
               B_Last_rank_mathched[_fightEvent]=numB[_fightEvent];
               A_Last_rank_mathched[_fightEvent]=numA[_fightEvent];
           }   


      RankOfJoiner[msg.sender][_fightEvent]=AmountJoin[_fightEvent];
      AddrOfJoiner[AmountJoin[_fightEvent]][_fightEvent]=msg.sender;
      SideOfJoiner[msg.sender][_fightEvent]= _side;
      AmountOfJoiner[msg.sender][_fightEvent] +=_place;
      PlaceTimeOfJoiner[msg.sender][_fightEvent]=placetime; 

     Logs.push(Log(NumLogs,placetime, msg.sender, 2, _side,_PlacePoint,_fightEvent,WatAddr ));
       NumLogs++;
       return Logs.length-1;

     }

     function viewJoiner(uint _fightEvent, uint _rank)public view returns(address,uint,uint,uint){
       return (AddrOfJoiner[_rank][_fightEvent],
                 SideOfJoiner[(AddrOfJoiner[_rank][_fightEvent])][_fightEvent],
                  AmountOfJoiner[(AddrOfJoiner[_rank][_fightEvent])][_fightEvent],
                  PlaceTimeOfJoiner[(AddrOfJoiner[_rank][_fightEvent])][_fightEvent] 
             );
            }
     

     function viewEvent1(uint _event)public view returns(address,uint,uint,uint,uint){
         return (Setter[_event], TimeStart[_event], TimeEnd[_event],
              A_side_accumalted[_event], B_side_accumalted[_event]);     }


     function viewEvent2(uint _event)public view returns(uint,uint,uint,uint,uint){
         return 
             (sum_accumalted[_event], numA[_event], 
              numB[_event],AmountJoin[_event], status[_event]);
     }

         // 3 = A win, 4 = B win, 5 = draw
      function JudgeEvent(uint _fightEvent, uint _side)public returns(uint){
            require(judgeAble[msg.sender]==1);
            require(status[_fightEvent]<3);
            require(TimeEnd[_fightEvent]<block.timestamp);
            status[_fightEvent]=_side;
            Match_judge[msg.sender]+=1;
            AccPlaced[msg.sender]+=sum_accumalted[_fightEvent];
            uint reward = sum_accumalted[_fightEvent]*JudgeFee/1000;
            decent.transfer(msg.sender, reward);
            uint sysFee = sum_accumalted[_fightEvent]*SystemFee/1000;
            decent.transfer(WatAddr, sysFee); 

            Logs.push(Log(NumLogs,block.timestamp, msg.sender, 5, _side,0,_fightEvent,WatAddr ));
            NumLogs++;
           return Logs.length-1;
            
      }
         //won or draw result
      function PlayerClaimReward(uint _fightEvent)public returns(uint){
            require(EventClaimed[msg.sender][_fightEvent]==false);
            require((status[_fightEvent]==SideOfJoiner[msg.sender][_fightEvent])||
            (status[_fightEvent]==5));

                uint reward; uint SumReward; uint _sysfee;

            if(status[_fightEvent]!=5){
             EventClaimed[msg.sender][_fightEvent]=true;

             if((A_Last_rank_mathched[_fightEvent]>=A_RankOfJoiner[msg.sender][_fightEvent])
            ||(B_Last_rank_mathched[_fightEvent]>=B_RankOfJoiner[msg.sender][_fightEvent])){
                 reward = AmountOfJoiner[msg.sender][_fightEvent];                 
                 SumReward = 2*reward; _sysfee = 2*reward*SystemFee/1000;
                 //SystemFee_Withdrawable +=_sysfee;
                 SumReward -=SumReward*(JudgeFee+SystemFee)/1000;
                 decent.transfer(msg.sender, SumReward);
             }

            if((A_Last_rank_mathched[_fightEvent]<A_RankOfJoiner[msg.sender][_fightEvent])
            ||(B_Last_rank_mathched[_fightEvent]< B_RankOfJoiner[msg.sender][_fightEvent])){
                 reward = AmountOfJoiner[msg.sender][_fightEvent];                 
                 SumReward = reward; _sysfee = reward*SystemFee/1000;
                 //SystemFee_Withdrawable +=_sysfee;
                 SumReward -=SumReward*(JudgeFee+SystemFee)/1000;
                 decent.transfer(msg.sender, SumReward);
               }
             Logs.push(Log(NumLogs,block.timestamp, msg.sender, 6, SideOfJoiner[msg.sender][_fightEvent],SumReward,_fightEvent,WatAddr ));
            }


             if(status[_fightEvent]==5){
                 EventClaimed[msg.sender][_fightEvent]=true;
                 reward = AmountOfJoiner[msg.sender][_fightEvent];
                 _sysfee = reward*SystemFee/1000; //SystemFee_Withdrawable +=_sysfee;
                  reward -=reward*(JudgeFee+SystemFee)/1000;
                  decent.transfer(msg.sender, reward);
                  Logs.push(Log(NumLogs,block.timestamp, msg.sender, 6, SideOfJoiner[msg.sender][_fightEvent],reward/(10**18),_fightEvent,WatAddr ));
             }


                     
            
            NumLogs++;
            return Logs.length-1;
            
      }


      function ClaimofLoseUnmatched(uint _fightEvent)public returns(uint){
            require(status[_fightEvent]!=5);
            require(status[_fightEvent]!=SideOfJoiner[msg.sender][_fightEvent]);
            require(EventClaimed[msg.sender][_fightEvent]==false);
           EventClaimed[msg.sender][_fightEvent]=true;
           uint back;

           if(SideOfJoiner[msg.sender][_fightEvent]==3){
             if(A_Sum_Place_At_Join[msg.sender][_fightEvent]>B_side_accumalted[_fightEvent]){
                 uint diff = A_Sum_Place_At_Join[msg.sender][_fightEvent]-B_side_accumalted[_fightEvent];
                
                 if(diff<AmountOfJoiner[msg.sender][_fightEvent]){
                       back = AmountOfJoiner[msg.sender][_fightEvent]-B_side_accumalted[_fightEvent];
                      back -= back*(JudgeFee+SystemFee)/1000;
                      decent.transfer(msg.sender,back);
                 }

                 if(diff>AmountOfJoiner[msg.sender][_fightEvent]){
                       back = AmountOfJoiner[msg.sender][_fightEvent];
                      back -= back*(JudgeFee+SystemFee)/1000;
                      decent.transfer(msg.sender,back);
                 }  

             }


           } 
           
           if(SideOfJoiner[msg.sender][_fightEvent]==4){
               if(B_Sum_Place_At_Join[msg.sender][_fightEvent]>A_side_accumalted[_fightEvent]){
                 uint diff = B_Sum_Place_At_Join[msg.sender][_fightEvent]-A_side_accumalted[_fightEvent];
                
                 if(diff<AmountOfJoiner[msg.sender][_fightEvent]){
                       back = AmountOfJoiner[msg.sender][_fightEvent]-A_side_accumalted[_fightEvent];
                      back -= back*(JudgeFee+SystemFee)/1000;
                      decent.transfer(msg.sender,back);
                 }

                 if(diff>AmountOfJoiner[msg.sender][_fightEvent]){
                       back = AmountOfJoiner[msg.sender][_fightEvent];
                      back -= back*(JudgeFee+SystemFee)/1000;
                      decent.transfer(msg.sender,back);
                 }  

             }
  

               
           } 
           

          Logs.push(Log(NumLogs,block.timestamp, msg.sender, 6, SideOfJoiner[msg.sender][_fightEvent],back/(10**18),_fightEvent,WatAddr ));
          NumLogs++;
          return Logs.length-1;


      }


}