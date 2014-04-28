package controllers

import play.api.mvc.{Action, Controller}
import play.api.libs.json.Json
import play.api.Routes

object ArtistsController extends Controller {
  def search = Action { request =>
    Ok("Here is a result for a searched artist.")
  }

  def javascriptRoutes = Action { implicit request =>
    Ok(Routes.javascriptRouter("jsRoutes")(routes.javascript.ArtistsController.search)).as(JAVASCRIPT)
  }
}
