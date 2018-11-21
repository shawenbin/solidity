/*
https://github.com/shawenbin/worldWar
uint of amount is Gwei
emit 一个 event 记录游戏过程 
*/
pragma solidity ^0.4.25;
contract worldWar {
    gameConfig config;
    team[] Teams;
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    enum Country_Region { China, Japan, UN }
    mapping(address => uint56) withdrawable; // Available eth can draw in Wei
    constructor() public {
        config = gameConfig({developer:msg.sender, currertGame:0, currertRound:0, teamCharge:[uint56(1),2]});
        newGame();
    }
    struct gameConfig {
        address developer;
        uint8 currertRound; // max 256
        uint16 currertGame; // max 16777216
        uint56[2] teamCharge;  // cost of building a team in Gwei, fibonacci number, [last, current]
        //defint endTime
    }
    struct team {
        address originator;
        string introduce;
        Country_Region onBehalf;
        teamRule rule;
        uint8[2] lifeCycle; // [first, last] round
        uint8 attackIndex;  // team's index in arrary
        uint56 attackPower; // max 72,057,594 eth
        uint56 totalInjury;
        member[] Members;
    }
    struct member {
        address addr;
        string message;
        uint8 attackIndex;  // max 256
        uint56 amount;
    }
    struct subtotal {
        uint8 index;
        uint56 total;
    }
    function newGame() private {
        config.teamCharge = [1,2];
        Teams.push(team({originator:config.developer, introduce:"Welcome to Join us", onBehalf:Country_Region.UN, rule:teamRule.democratic, lifeCycle:[0,0], attackIndex:0, attackPower:0, totalInjury:0, Members:new member[](0)}));
    }
    function newTeam(Country_Region onBehalf, teamRule rule, string introduce, uint8 attackIndex, string message) public payable {
        uint56 amount = uint56(msg.value / 1000000000 - config.teamCharge[1]);
        require(amount > 0, "The amount is not enough to build up a team.");
        uint index = Teams.push(team({originator:msg.sender, introduce:introduce, onBehalf:onBehalf, rule:rule, lifeCycle:[config.currertRound,config.currertRound], attackIndex:attackIndex, attackPower:amount, totalInjury:0, Members:new member[](0)}));
        Teams[index-1].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        if(attackIndex < Teams.length)
            Teams[attackIndex].totalInjury += amount;
        config.teamCharge = [config.teamCharge[1], config.teamCharge[0] + config.teamCharge[1]];    // calculate next fibonacci number
        withdrawable[config.developer] += uint56(msg.value - amount);  // team building cost transfer to developer account
        }
    function joinTeam(uint8 teamIndex, uint8 attackIndex, string message) public payable {
        uint56 amount = uint56(msg.value / 1000000000);
        require(amount > 0, "The amount must be greater than 1 Gwei.");
        for(uint128 i = 0; i < Teams[teamIndex].Members.length; i++) {
            if(Teams[teamIndex].Members[i].addr == msg.sender) {    // has joined before
                member memory thisMember = member({addr:msg.sender, message:message, amount:Teams[teamIndex].Members[i].amount+amount, attackIndex:attackIndex});
                while (i++ < Teams[teamIndex].Members.length - 1)
                    Teams[teamIndex].Members[i-1] = Teams[teamIndex].Members[i];    // move this member to the end , in order to get last 3 messages
                Teams[teamIndex].Members[i-1] = thisMember;
                break;
            }
        }
        if(i == Teams[teamIndex].Members.length)                    // first time to join
            Teams[teamIndex].Members.push(member({addr:msg.sender, message:message, amount:amount, attackIndex:attackIndex}));
        Teams[teamIndex].attackPower += amount;
        sumAttack(teamIndex);
        sumInjury();
    }
    function attackTeam(uint8 attackTeamID) public payable {
        
    }
    function sumAttack(uint8 index) public {
        uint56 maxAmount = 0;
        if(Teams[index].rule == teamRule.dictatorship) {    // maximum amount is leader
            for(uint16 i = 0; i < Teams[index].Members.length; i++) {
                if(Teams[index].Members[i].amount >= maxAmount)
                    (maxAmount, Teams[index].attackTeamID) = (Teams[index].Members[i].amount, Teams[index].Members[i].attackTeamID);
            }
        }
        else if(Teams[index].rule == teamRule.democratic) { // subtotal everyone
            subtotal[] memory Subtotals = new subtotal[](Teams.length);
            uint8 t = 0;   // effective length of subtotal
            for(i = 0; i < Teams[index].Members.length; i++) {
                for(uint8 j = 0; j <= t; j++) {
                    if(Subtotals[j].key == Teams[index].Members[i].attackTeamID) {
                        Subtotals[j].total += Teams[index].Members[i].amount;
                        if(Subtotals[j].total >= maxAmount) {
                            (maxAmount, Teams[index].attackTeamID) = (Subtotals[j].total, Subtotals[j].key);
                            break;
                        }
                    }
                    else if(j == t) {
                        t++;
                        Subtotals[t] = subtotal({key:Teams[index].Members[i].attackTeamID, total:Teams[index].Members[i].amount});
                        if(Subtotals[t].total >= maxAmount) {
                            (maxAmount, Teams[index].attackTeamID) = (Subtotals[t].total, Subtotals[t].key);
                            break;
                        }
                    }
                }
            }
        }
    }
    function sumInjury() public {
        uint56[] memory subInjury = uint56[Teams.length];
        for(uint8 i = 0; i < Teams.length; i++)
            subInjury[Teams[i].attackIndex].totalInjury += Teams[i].attackPower;
        for(i = 0; i < Teams.length; i++)
            Teams[i].totalInjury = subInjury[i];
        // 判断被攻击者还活着
        
        
    }
    function seekMax() internal returns (uint16) {
        
    }
    
}
