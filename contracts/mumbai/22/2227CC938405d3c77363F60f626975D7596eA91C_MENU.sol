/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

contract MENU
 {
     address public consumer=msg.sender;
     uint wallet = consumer.balance;
     
     enum food {
                nothing,roast_beef,chicken,sausages,pepperoni,vegetable,
                special,cheese,american,barbecue,jalapeno,
                soda,sprite,water,
                salad,fench_fties,extra_sauce
                }

     food[] public order;
  
     function balance()public view returns(uint your_balance){
         return wallet;
     }


     function Pizza_roast_beef (int8 how_much) public returns(string memory){
         if(how_much>20){
             return "sorry! we couldn't provide it for tonight please connect to management";
         }
         else if(how_much<0){
             for(int8 i; i<(-how_much); i++){
                 for(uint8 j; j < order.length; j++){
                     if(order[j]==food.roast_beef){
                         order[j]=food.nothing;
                         break;
                     }
                 }
             }
         }
         for(int8 i; i < how_much; i++){
             order.push(food.roast_beef);
         }
         return "ok recorded.keep on if you have more orders otherwise press checkout";
     }   

     function Pizza_chicken (int8 how_much) public returns(string memory){
         if(how_much>20){
             return "sorry! we couldn't provide it for tonight please connect to management";
         }
         else if(how_much<0){
             for(int8 i; i<(-how_much); i++){
                 for(uint8 j; j < order.length; j++){
                     if(order[j]==food.chicken){
                         order[j]=food.nothing;
                         break;
                     }
                 }
             }
         }
         for(int8 i=0;i<how_much;i++){
             order.push(food.chicken);
         }
         return "ok recorded.keep on if you have more orders otherwise press checkout";
     }   

     function Pizza_sausages (int8 how_much) public returns(string memory){
         if(how_much>20){
             return "sorry! we couldn't provide it for tonight please connect to management";
         }
         else if(how_much<0){
             for(int8 i; i<(-how_much); i++){
                 for(uint8 j; j < order.length; j++){
                     if(order[j]==food.sausages){
                         order[j]=food.nothing;
                         break;
                     }
                 }
             }
         }
         for(int8 i=0;i<how_much;i++){
             order.push(food.sausages);
         }
         return "ok recorded.keep on if you have more orders otherwise press checkout";
     }   
     
     function Pizza_pepperoni (int8 how_much) public returns(string memory){
         if(how_much>20){
             return "sorry! we couldn't provide it for tonight please connect to management";
         }
         else if(how_much<0){
             for(int8 i; i<(-how_much); i++){
                 for(uint8 j; j < order.length; j++){
                     if(order[j]==food.pepperoni){
                         order[j]=food.nothing;
                         break;
                     }
                 }
             }
         }
         for(int8 i=0;i<how_much;i++){
             order.push(food.pepperoni);
         }
         return "ok recorded.keep on if you have more orders otherwise press checkout";
     }

     function Pizza_vegetable (int8 how_much) public returns(string memory){
         if(how_much>20){
             return "sorry! we couldn't provide it for tonight please connect to management";
         }
         else if(how_much<0){
             for(int8 i; i<(-how_much); i++){
                 for(uint8 j; j < order.length; j++){
                     if(order[j]==food.vegetable){
                         order[j]=food.nothing;
                         break;
                     }
                 }
             }
         }
         for(int8 i=0;i<how_much;i++){
             order.push(food.vegetable);
         }
         return "ok recorded.keep on if you have more orders otherwise press checkout";
     }      





     function checkout()public view returns (uint8 pizza_roast_beef,uint8 pizza_chicken,
                           uint8 pizza_sausages,uint8 pizza_pepperoni,uint8 pizza_vegetable){
         uint8 Pizza_roast_beef_;
         uint8 Pizza_chicken_;
         uint8 Pizza_sausages_;
         uint8 Pizza_pepperoni_;
         uint8 Pizza_vegetable_;

         for(uint8 i; i<order.length; i++){
            if(order[i]==food.roast_beef){Pizza_roast_beef_ ++;}
            if(order[i]==food.chicken){Pizza_chicken_ ++;}
            if(order[i]==food.sausages){Pizza_sausages_ ++;}
            if(order[i]==food.pepperoni){Pizza_pepperoni_ ++;}
            if(order[i]==food.vegetable){Pizza_vegetable_ ++;}            
         }

         pizza_chicken = Pizza_chicken_;
         pizza_roast_beef = Pizza_roast_beef_;
         pizza_sausages = Pizza_sausages_;
         pizza_pepperoni = Pizza_pepperoni_;
         pizza_vegetable = Pizza_vegetable_;
     }
 }