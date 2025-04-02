import { ConnectButton } from "@mysten/dapp-kit";
import { Box, Flex, Heading } from "@radix-ui/themes";
import Nav from "./function/nav.tsx";

function App() {
    return (
        <>
            <Box style={{ background: "black", padding: "20px" }}>
                <Flex align="center" justify="between" style={{ width: '100%' }}>
                    <Heading style={{ color: 'white' }}>FAUCET FOR PLEDGEX</Heading>
                    <ConnectButton />
                </Flex>
            </Box>
            <Nav/>
        </>

    );
}

export default App;