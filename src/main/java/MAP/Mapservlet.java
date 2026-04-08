package MAP;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

import org.json.JSONArray;
import org.json.JSONObject;

@WebServlet("/mapdata")
public class Mapservlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        String jdbcURL = "jdbc:mysql://localhost:3306/smartcampus";
        String dbUser = "root";
        String dbPassword = "root";

        try (PrintWriter out = resp.getWriter()) {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
                 Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT * FROM smart")) {

                // ✅ Correct type here
                JSONArray locations = new JSONArray();

                while (rs.next()) {
                    JSONObject loc = new JSONObject();
                    loc.put("name", rs.getString("name"));
                    loc.put("lat", rs.getDouble("latitude"));
                    loc.put("lng", rs.getDouble("longitude"));
                    locations.put(loc);  // ✅ No error now
                }

                out.print(locations.toString());
            }

        } catch (Exception e) {
            e.printStackTrace();
            resp.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            resp.getWriter().print("{\"error\":\"Database error: " + e.getMessage() + "\"}");
        }
    }
}
