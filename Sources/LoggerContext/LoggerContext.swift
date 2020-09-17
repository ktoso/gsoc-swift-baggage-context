import Context
import Logging

public protocol LoggerContextCarrier: Context {
    var logger: Logger { get }
}
