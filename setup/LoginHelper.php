<?php
/**
 * Displays default login credentials on login pages, so it's very easy to access the control panel.
 */

namespace modules;

use Craft;
use craft\web\View;
use craft\events\TemplateEvent;

use yii\base\Event;
use yii\base\Module;

/**
 * The main Craft module class.
 */
class LoginHelper extends Module
{
	/**
	 * @inheritdoc
	 * @see yii\base\Module
	 */
	public function init()
	{
		if (Craft::$app->getRequest()->getIsCpRequest()) {
            Event::on(
				View::class,
				View::EVENT_BEFORE_RENDER_TEMPLATE,
				function (TemplateEvent $event) {
					if (isset(Craft::$app->requestedAction)
						&& Craft::$app->requestedAction->id = 'login'
						&& is_a(Craft::$app->requestedAction->controller, craft\controllers\UsersController::class))
					{
						Craft::$app->getView()->registerJs(<<<EOT
$('#password-field').after('<p class="centeralign"><code>User: admin&nbsp;&nbsp;|&nbsp;&nbsp;Pass: craftdev</code></p>');
EOT
						);
					}
				}
			);
		}
		
		parent::init();
	}

}
