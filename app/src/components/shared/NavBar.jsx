import { useNavigate, useLocation } from "@solidjs/router";
import { Button } from "../ui/Button";
import { userRole } from "@features/auth/stores/auth";

export const NavBar = () => {
    const navigate = useNavigate();
    const location = useLocation();

    return (
        <div class="flex items-center space-x-4 px-4 pt-2">
            <Button 
                onClick={() => navigate("/")} 
                variant={location.pathname === "/" ? "active" : "primary"}
            >
                Home
            </Button>
            <Button 
                onClick={() => navigate("/inventory")} 
                variant={location.pathname === "/inventory" ? "active" : "primary"}
            >
                Inventory
            </Button>
            {(userRole() === "admin" || userRole() === "super admin") && (
            <Button 
                onClick={() => navigate("/map")} 
                variant={location.pathname === "/map" ? "active" : "primary"}
            >
                Map
            </Button>
            )}
            {(userRole() === "admin" || userRole() === "super admin") && (
                <Button onClick={() => navigate("/admin")}>Admin</Button>
            )}
        </div>
    );
};