import  { Component } from 'react';
// import CreateProfile from "./createProfile.tsx";
// import CreateAccountBook from "./createAccountBook.tsx";
// import AddContent from "./createContent.tsx";
import { Box } from "@radix-ui/themes";
import CreateFlagPool from "./createFlagPool.tsx";
import AddFlagPool from "./addFlagPool.tsx";
import EditSwapNum from "./editSwapNum.tsx";
import Register from "./registerUser.tsx";
import CheckUserAccount from "./CheckUserAccount.tsx";
import CreateChallenge from "./CreateChallenge.tsx";
import SendFlagReward from "./SendFlagReward.tsx";
class Nav extends Component {


    render() {
        // const { activeModule } = this.state;
        return (
            <Box style={{ background: "black", padding: "20px" }}>
             <CreateFlagPool onSuccess={console.log}/>
              <AddFlagPool onSuccess={console.log}/>
              <EditSwapNum onSuccess={console.log}/>
              <Register onSuccess={console.log}/>
              <CheckUserAccount onSuccess={console.log}/>
              <CreateChallenge onSuccess={console.log}/>
              <SendFlagReward onSuccess={console.log}/>
            </Box>
        );
    }
}

export default Nav;