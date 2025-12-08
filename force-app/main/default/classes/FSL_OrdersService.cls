@RestResource(urlMapping='/fslServices/*')
global class FSL_OrdersService {

    @testVisible private static Boolean throwException = false;

    @HttpGet
    global static FSL_OrdersServiceHandler.GetSlotsResponseWrapper handleGetRequest() {
        try {
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            String path = RestContext.request.requestURI.substringAfter('/fslServices/');

            if (path.contains('getSlots')) {
                return new FSL_OrdersServiceHandler.GetSlotsResponseWrapper(FSL_OrdersServiceHandler.getSlots(path)); 
            } else {
                RestContext.response.statusCode = 404;
                return new FSL_OrdersServiceHandler.GetSlotsResponseWrapper(new Map<String, Object>{
                    'errorCode' => 'INVALID_PATH',
                    'message' => 'The provided path is invalid: ' + path
                });
            }
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_OrdersService.class.getName(), e.getMessage());
            return new FSL_OrdersServiceHandler.GetSlotsResponseWrapper(new Map<String, String>{
                'errorCode' => 'INTERNAL_SERVER_ERROR',
                'message' => e.getMessage()
            });
        }
    }

    @HttpPost
    global static FSL_OrdersServiceHandler.BookAppointmentResponseWrapper handlePostRequest() {
        try {
            if (Test.isRunningTest() && throwException) {
                throw new CustomException();
            }

            String path = RestContext.request.requestURI.substringAfter('/fslServices/');
            String requestBody = RestContext.request.requestBody.toString();
            
            if (path.equalsIgnoreCase('bookAppointment')) {
                return new FSL_OrdersServiceHandler.BookAppointmentResponseWrapper(FSL_OrdersServiceHandler.bookAppointment(requestBody));
            } else {
                RestContext.response.statusCode = 404;
                return new FSL_OrdersServiceHandler.BookAppointmentResponseWrapper(new Map<String, Object>{
                    'errorCode' => 'INVALID_PATH',
                    'message' => 'The provided path is invalid: ' + path
                });
            }
        } catch (Exception e) {
            ExceptionUtil.publishFSLException('Internal Error', 'FSL', FSL_OrdersService.class.getName(), e.getMessage());
            return new FSL_OrdersServiceHandler.BookAppointmentResponseWrapper(new Map<String, String>{
                'errorCode' => 'INTERNAL_SERVER_ERROR',
                'message' => e.getMessage()
            });
        }
    }   
}