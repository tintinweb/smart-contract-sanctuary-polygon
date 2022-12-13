// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/**
 * @title Owner
 * @dev Set & change owner
 */


 contract certificate
 {
    address private owner;

  constructor (){

    owner=msg.sender;
   }

    struct parameters{
    uint256 candiid;
    uint256 certificateid;
    string name;
    uint256 time;
    uint256 duration;
    string certiname;
   // string status;
   // uint256 marks;
   }
   mapping (uint256=>mapping(uint256=>parameters)) public certification;
   mapping (address=>bool)public employervalid;
   mapping (address=>bool)public candidate;
   mapping (address=>mapping(uint256=>bool)) public cerad;
   mapping (address=>mapping(uint256=>bool)) public canad;

   
   modifier onlyemployer()
   {
        require(employervalid[msg.sender]==true || msg.sender==owner ,'no access');
        _;

   }

   modifier onlyOwner()
   {
       require(msg.sender==owner,'invalid owner');
       _;
   }
   
   modifier onlyCandidate()
   {
       require(candidate[msg.sender]==true,'no credentials');
       _;
   }

   function addemployer(address employer)public  onlyOwner{

       employervalid[employer] = true;
   } 


    function removeemployer(address employer)public  onlyOwner{

       employervalid[employer] = false;
   } 

    function removecandidate(address _candidate)public  onlyemployer{

       candidate[_candidate] = false;
   } 

   function issue(address _candidate, uint256 _candiid, uint256 _certificateid, string memory _name , uint256 _duration , string memory _certiname   ) public onlyemployer {
       
        certification[_certificateid][_candiid]= parameters(
                 {
                     candiid:_candiid,
                     certificateid:_certificateid,
                     name:_name,
                     time:block.timestamp,
                     duration:_duration,
                     certiname:_certiname
                    // status:_status,
                     //marks:_marks

                 }
 
        );

     
        candidate[_candidate]=true;

   }


   function candidateShare(uint256 _certificateid,address _get, uint256 _candiid)public onlyCandidate{
     
      cerad[_get][_certificateid]=true;
      canad[_get][_candiid]=true;


     
       
     
 
   }

      function recandidateShare(uint256 _certificateid,address _get,uint256 _candiid)public onlyCandidate{
     
          cerad[_get][_certificateid]=false;
          canad[_get][_candiid]=false;


         
 
   }


   function claim(uint256 _certificatid , uint256 _candiid)public  view  onlyCandidate returns (uint256,uint256,string memory,uint256,uint256,string memory){

      return (
        certification[ _certificatid][ _candiid].candiid,
        certification[ _certificatid][ _candiid].certificateid,
        certification[ _certificatid][ _candiid].name,
        certification[ _certificatid][ _candiid].time,
        certification[ _certificatid][ _candiid].duration,
        certification[ _certificatid][ _candiid].certiname
   //   certification[ _certificatid][msg.sender].status,
     // certification[ _certificatid][ _candiid].marks

      );

   }


   function share(uint256 _certificatid ,uint256 _candiid) public view returns (uint256,uint256,string memory,uint256,uint256,string memory) {
       require(cerad[msg.sender][_certificatid]==true,'not shared');
       require(canad[msg.sender][_candiid]==true,'not shared');
            return (
        certification[ _certificatid][ _candiid].candiid,
        certification[ _certificatid][ _candiid].certificateid,
        certification[ _certificatid][ _candiid].name,
        certification[ _certificatid][ _candiid].time,
        certification[ _certificatid][ _candiid].duration,
        certification[ _certificatid][ _candiid].certiname
   //   certification[ _certificatid][msg.sender].status,
      //certification[ _certificatid][ _candiid].marks

      );
       


   }




 }