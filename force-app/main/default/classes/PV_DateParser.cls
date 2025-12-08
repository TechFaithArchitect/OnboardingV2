public class PV_DateParser {
    private static final Map<String, String> months = new Map<String, String>{
        'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04',
        'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08',
        'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12'
    };

    public static DateTime parseRFC2822(String input) {
        if (String.isBlank(input)) {
            return null;
        }

        try {
            input = input.replace(' +0000', '');

            List<String> parts = input.substring(input.indexOf(', ') + 2).split(' '); 
            List<String> dateParts = new List<String>{ parts[2], months.get(parts[1]), parts[0] };
            List<String> timeParts = parts[3].split(':');

            return DateTime.newInstanceGMT(
                Integer.valueOf(dateParts[0]),
                Integer.valueOf(dateParts[1]),
                Integer.valueOf(dateParts[2]),
                Integer.valueOf(timeParts[0]),
                Integer.valueOf(timeParts[1]),
                Integer.valueOf(timeParts[2])
            );
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', '', PV_DateParser.class.getName(), e.getMessage());
            return null;
        }
    }
}